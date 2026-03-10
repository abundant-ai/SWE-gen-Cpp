#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state with fixed versions)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin.cpp" "modules/core/test/test_intrin.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin512.simd.hpp" "modules/core/test/test_intrin512.simd.hpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin_utils.hpp" "modules/core/test/test_intrin_utils.hpp"

checks_passed=0
checks_failed=0

# The fix adds AVX-512 support to OpenCV's universal intrinsics layer.
# The buggy state (after bug.patch) has AVX-512 support removed.
# The fixed state (after fix.patch) restores AVX-512 support.

# Check 1: intrin_avx512.hpp should exist (restored in the fix)
if [ -f modules/core/include/opencv2/core/hal/intrin_avx512.hpp ]; then
    echo "PASS: intrin_avx512.hpp exists (fixed version with AVX-512 support)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx512.hpp missing (buggy version without AVX-512 support)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: CMakeLists.txt should include test_intrin512 dispatch (fixed version)
if grep -q 'ocv_add_dispatched_file_force_all(test_intrin512 TEST AVX512_SKX)' modules/core/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt has test_intrin512 AVX512_SKX dispatch (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt missing test_intrin512 AVX512_SKX dispatch (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: intrin.hpp should include intrin_avx512.hpp (fixed version)
if grep -q '#include "opencv2/core/hal/intrin_avx512.hpp"' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp includes intrin_avx512.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp does not include intrin_avx512.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: intrin.hpp should have SIMD512 typedefs (fixed version)
if grep -q 'typedef v_uint8x64    v_uint8;' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp has SIMD512 typedefs (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp missing SIMD512 typedefs (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: intrin.hpp should define V_RegTraits for v512 types (fixed version)
if grep -q 'CV_DEF_REG_TRAITS(v512, v_uint8x64, uchar, u8' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp defines V_RegTraits for v512 types (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp missing V_RegTraits for v512 types (buggy version)" >&2
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
