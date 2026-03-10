#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/cudaimgproc/test"
cp "/tests/modules/cudaimgproc/test/test_histogram.cpp" "modules/cudaimgproc/test/test_histogram.cpp"

checks_passed=0
checks_failed=0

# PR #13764 adds CV_16UC1 support for cuda::CLAHE
# HEAD (fb8e652c3f20d377e9f935faee370ed28fb60122): Fixed version with CV_16UC1 support
# BASE (after bug.patch): Buggy version without CV_16UC1 support
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: cuda_types.hpp should have PtrStepSzus and PtrStepus typedefs (fixed version)
if grep -q 'typedef PtrStepSz<unsigned short> PtrStepSzus;' modules/core/include/opencv2/core/cuda_types.hpp; then
    echo "PASS: cuda_types.hpp has PtrStepSzus typedef (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cuda_types.hpp does not have PtrStepSzus typedef (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: cuda_types.hpp should have PtrStepus typedef (fixed version)
if grep -q 'typedef PtrStep<unsigned short> PtrStepus;' modules/core/include/opencv2/core/cuda_types.hpp; then
    echo "PASS: cuda_types.hpp has PtrStepus typedef (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cuda_types.hpp does not have PtrStepus typedef (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: perf_histogram.cpp should have MatType parameter (fixed version)
if grep -q 'DEF_PARAM_TEST(Sz_ClipLimit, cv::Size, double, MatType);' modules/cudaimgproc/perf/perf_histogram.cpp; then
    echo "PASS: perf_histogram.cpp has MatType parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_histogram.cpp does not have MatType parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: perf_histogram.cpp should test both CV_8UC1 and CV_16UC1 (fixed version)
if grep -q 'Values(MatType(CV_8UC1), MatType(CV_16UC1))' modules/cudaimgproc/perf/perf_histogram.cpp; then
    echo "PASS: perf_histogram.cpp tests both CV_8UC1 and CV_16UC1 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_histogram.cpp does not test CV_16UC1 (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: clahe.cu should have calcLutKernel_16U function (fixed version)
if grep -q '__global__ void calcLutKernel_16U' modules/cudaimgproc/src/cuda/clahe.cu; then
    echo "PASS: clahe.cu has calcLutKernel_16U function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clahe.cu does not have calcLutKernel_16U function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: clahe.cu should have calcLut_16U function (fixed version)
if grep -q 'void calcLut_16U' modules/cudaimgproc/src/cuda/clahe.cu; then
    echo "PASS: clahe.cu has calcLut_16U function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clahe.cu does not have calcLut_16U function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: histogram.cpp should support both CV_8UC1 and CV_16UC1 (fixed version)
if grep -q 'CV_Assert( type == CV_8UC1 || type == CV_16UC1 );' modules/cudaimgproc/src/histogram.cpp; then
    echo "PASS: histogram.cpp supports both CV_8UC1 and CV_16UC1 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: histogram.cpp only supports CV_8UC1 (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_histogram.cpp should have MatType parameter (fixed version)
if grep -q 'PARAM_TEST_CASE(CLAHE, cv::cuda::DeviceInfo, cv::Size, ClipLimit, MatType)' modules/cudaimgproc/test/test_histogram.cpp; then
    echo "PASS: test_histogram.cpp has MatType parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_histogram.cpp does not have MatType parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_histogram.cpp should test clip limit 5.0 (fixed version - exposes residual bug)
if grep -q 'testing::Values(0.0, 5.0, 10.0, 20.0, 40.0)' modules/cudaimgproc/test/test_histogram.cpp; then
    echo "PASS: test_histogram.cpp tests clip limit 5.0 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_histogram.cpp does not test clip limit 5.0 (buggy version)" >&2
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
