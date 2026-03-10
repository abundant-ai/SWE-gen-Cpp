#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test/cpu"
cp "/tests/modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp" "modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp"
mkdir -p "modules/gapi/test/cpu"
cp "/tests/modules/gapi/test/cpu/gapi_imgproc_tests_fluid.cpp" "modules/gapi/test/cpu/gapi_imgproc_tests_fluid.cpp"

checks_passed=0
checks_failed=0

# PR #13070: Sobel filter optimization with new implementation files
# For harbor testing:
# - HEAD (a8968169a855925950a72db1d7e87eab7efacdcf): Fixed version with optimized implementation
# - BASE (after bug.patch): Buggy version without optimization (reference implementation)
# - FIXED (after fix.patch): Back to fixed version

# Check 1: CMakeLists.txt should include gfluidimgproc_func.cpp (line ~72)
if grep -q 'src/backends/fluid/gfluidimgproc_func.cpp' modules/gapi/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt includes gfluidimgproc_func.cpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt missing gfluidimgproc_func.cpp - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: saturate.hpp should include <cmath>
if grep -q '#include <cmath>' modules/gapi/include/opencv2/gapi/own/saturate.hpp; then
    echo "PASS: saturate.hpp includes <cmath> - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: saturate.hpp missing <cmath> include - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gfluidimgproc_func.cpp should exist (new file in fixed version)
if [ -f "modules/gapi/src/backends/fluid/gfluidimgproc_func.cpp" ]; then
    echo "PASS: gfluidimgproc_func.cpp exists - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidimgproc_func.cpp missing - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: gfluidimgproc_func.hpp should exist (new file in fixed version)
if [ -f "modules/gapi/src/backends/fluid/gfluidimgproc_func.hpp" ]; then
    echo "PASS: gfluidimgproc_func.hpp exists - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidimgproc_func.hpp missing - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gfluidimgproc.cpp should include gfluidimgproc_func.hpp
if grep -q '#include "gfluidimgproc_func.hpp"' modules/gapi/src/backends/fluid/gfluidimgproc.cpp; then
    echo "PASS: gfluidimgproc.cpp includes gfluidimgproc_func.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidimgproc.cpp missing gfluidimgproc_func.hpp include - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: gfluidimgproc.cpp should call run_sobel_impl (optimized implementation)
if grep -q 'run_sobel_impl(out, in, width, chan, kx, ky, border, scale, delta, buf, y, y0);' modules/gapi/src/backends/fluid/gfluidimgproc.cpp; then
    echo "PASS: gfluidimgproc.cpp calls run_sobel_impl - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidimgproc.cpp missing run_sobel_impl call - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: run_sobel should have buf parameter (optimized version)
if grep -q 'float  \*buf\[\]' modules/gapi/src/backends/fluid/gfluidimgproc.cpp; then
    echo "PASS: run_sobel has buf parameter - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: run_sobel missing buf parameter - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gapi_imgproc_perf_tests_fluid.cpp should exist (new file in fixed version)
if [ -f "modules/gapi/perf/cpu/gapi_imgproc_perf_tests_fluid.cpp" ]; then
    echo "PASS: gapi_imgproc_perf_tests_fluid.cpp exists - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_imgproc_perf_tests_fluid.cpp missing - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: gapi_imgproc_perf_tests_cpu.cpp should have SobelPerfTestCPU32F instantiation
if grep -q 'INSTANTIATE_TEST_CASE_P(SobelPerfTestCPU32F, SobelPerfTest,' modules/gapi/perf/cpu/gapi_imgproc_perf_tests_cpu.cpp; then
    echo "PASS: gapi_imgproc_perf_tests_cpu.cpp has SobelPerfTestCPU32F - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_imgproc_perf_tests_cpu.cpp missing SobelPerfTestCPU32F - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: gapi_imgproc_perf_tests_inl.hpp should use c.apply without std::move (fixed version)
if grep -A 2 'TEST_CYCLE()' modules/gapi/perf/common/gapi_imgproc_perf_tests_inl.hpp | grep -q 'c.apply(in_mat1, out_mat_gapi);'; then
    echo "PASS: gapi_imgproc_perf_tests_inl.hpp uses c.apply correctly - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_imgproc_perf_tests_inl.hpp has incorrect c.apply - buggy version" >&2
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
