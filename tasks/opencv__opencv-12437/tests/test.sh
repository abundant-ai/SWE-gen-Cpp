#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_affine3.cpp" "modules/calib3d/test/test_affine3.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"
mkdir -p "modules/photo/test"
cp "/tests/modules/photo/test/test_hdr.cpp" "modules/photo/test/test_hdr.cpp"

checks_passed=0
checks_failed=0

# PR #12437: Fix AVX2-baseline build test failures
# For harbor testing:
# - HEAD (90ed1060dbdb5a5b05a85851c101fdd279b512a5): Fixed version with relaxed tolerances
# - BASE (after bug.patch): Buggy version with strict tolerances that fail on AVX2
# - FIXED (after oracle applies fix): Back to fixed version with relaxed tolerances
#
# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: intrin_avx.hpp should have v_uint64x4::get0() with platform guards (fixed version)
if grep -A8 'uint64 get0() const' modules/core/include/opencv2/core/hal/intrin_avx.hpp | grep -q '#if defined __x86_64__ || defined _M_X64'; then
    echo "PASS: intrin_avx.hpp has v_uint64x4::get0() with platform guards - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp missing platform guards in v_uint64x4::get0() - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: intrin_avx.hpp should have v_int64x4::get0() with platform guards (fixed version)
if grep -B2 -A10 'int64 get0() const' modules/core/include/opencv2/core/hal/intrin_avx.hpp | grep -q '#if defined __x86_64__ || defined _M_X64'; then
    echo "PASS: intrin_avx.hpp has v_int64x4::get0() with platform guards - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp missing platform guards in v_int64x4::get0() - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: perf_split.cpp should NOT have platform-specific guards (fixed version removes them)
if ! grep -q '#if defined (__aarch64__)' modules/core/perf/perf_split.cpp && \
   grep -q 'SANITY_CHECK(mv, 2e-5);' modules/core/perf/perf_split.cpp; then
    echo "PASS: perf_split.cpp has unified SANITY_CHECK - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_split.cpp still has platform-specific guards - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: perf_arithm.cpp should have SANITY_CHECK with 2e-4 tolerance (fixed version)
if grep -A3 'if (CV_MAT_DEPTH(type) >= CV_32F)' modules/core/perf/opencl/perf_arithm.cpp | grep -q 'SANITY_CHECK(dst, 2e-4, ERROR_RELATIVE);'; then
    echo "PASS: perf_arithm.cpp has SANITY_CHECK with 2e-4 tolerance - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_arithm.cpp missing SANITY_CHECK with 2e-4 tolerance - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: perf_pnp.cpp should have SANITY_CHECK with 1e-4 tolerance (fixed version)
if grep -q 'SANITY_CHECK(rvec, 1e-4);' modules/calib3d/perf/perf_pnp.cpp && \
   grep -q 'SANITY_CHECK(tvec, 1e-4);' modules/calib3d/perf/perf_pnp.cpp; then
    echo "PASS: perf_pnp.cpp has SANITY_CHECK with 1e-4 tolerance - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_pnp.cpp missing SANITY_CHECK with 1e-4 tolerance - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: OpenCVCompilerOptions.cmake should have VERSION_GREATER 7.0 (fixed version)
if grep -q 'if(CV_GCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7.0)' cmake/OpenCVCompilerOptions.cmake; then
    echo "PASS: OpenCVCompilerOptions.cmake has VERSION_GREATER 7.0 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCVCompilerOptions.cmake missing VERSION_GREATER 7.0 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

echo "Checks passed: $checks_passed, Checks failed: $checks_failed"

if [ $checks_failed -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
