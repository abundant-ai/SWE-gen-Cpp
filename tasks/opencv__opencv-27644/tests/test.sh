#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgproc/test/ocl"
cp "/tests/modules/imgproc/test/ocl/test_histogram.cpp" "modules/imgproc/test/ocl/test_histogram.cpp"
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_goodfeaturetotrack.cpp" "modules/imgproc/test/test_goodfeaturetotrack.cpp"

checks_passed=0
checks_failed=0

# Check 1: accumulate functions accept CV_Bool masks in accum.cpp
if grep -q '_mask.type() == CV_Bool' modules/imgproc/src/accum.cpp; then
    echo "PASS: accum.cpp accepts CV_Bool masks (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: accum.cpp missing CV_Bool mask support (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: goodFeaturesToTrack accepts CV_BoolC1 masks in featureselect.cpp
if grep -q '_mask.type() == CV_BoolC1' modules/imgproc/src/featureselect.cpp; then
    echo "PASS: featureselect.cpp accepts CV_BoolC1 masks (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: featureselect.cpp missing CV_BoolC1 mask support (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: calcHist accepts CV_BoolC1 masks in histogram.cpp
if grep -q 'mask.type() == CV_BoolC1' modules/imgproc/src/histogram.cpp; then
    echo "PASS: histogram.cpp accepts CV_BoolC1 masks (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: histogram.cpp missing CV_BoolC1 mask support (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Test for boolean mask in test_histogram.cpp exists
if grep -q 'TEST(CalcHistMask, CheckMask)' modules/imgproc/test/ocl/test_histogram.cpp; then
    echo "PASS: test_histogram.cpp contains CheckMask test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_histogram.cpp missing CheckMask test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Test for boolean mask in test_goodfeaturetotrack.cpp exists
if grep -q 'TEST(Imgproc_GoodFeatureToT, mask)' modules/imgproc/test/test_goodfeaturetotrack.cpp; then
    echo "PASS: test_goodfeaturetotrack.cpp contains mask test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_goodfeaturetotrack.cpp missing mask test (buggy version)" >&2
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
