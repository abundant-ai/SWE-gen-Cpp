#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/video/test"
cp "/tests/modules/video/test/test_ecc.cpp" "modules/video/test/test_ecc.cpp"

checks_passed=0
checks_failed=0

# Check 1: tracking.hpp should have multi-channel documentation for computeECC (fixed version)
if grep -q "For multi-channel images (e.g., 3-channel RGB), the formula generalizes to:" modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: tracking.hpp has multi-channel documentation for computeECC (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tracking.hpp missing multi-channel documentation for computeECC (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tracking.hpp should mention "1 or 3 channels" for computeECC (fixed version)
if grep -q "must have either 1 or 3 channels and be of type CV_8U, CV_16U, CV_32F, or CV_64F" modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: tracking.hpp mentions 1 or 3 channels for computeECC (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tracking.hpp missing 1 or 3 channels mention for computeECC (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tracking.hpp should mention "1 or 3 channel" for findTransformECC (fixed version)
if grep -q "1 or 3 channel template image; CV_8U, CV_16U, CV_32F, CV_64F type" modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: tracking.hpp mentions 1 or 3 channel for findTransformECC (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tracking.hpp missing 1 or 3 channel mention for findTransformECC (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: perf_ecc.cpp should have IMREAD_COLOR and IMREAD_GRAYSCALE tests (fixed version)
if grep -q "CV_ENUM(ReadFlag, IMREAD_GRAYSCALE, IMREAD_COLOR)" modules/video/perf/perf_ecc.cpp; then
    echo "PASS: perf_ecc.cpp has ReadFlag enum with IMREAD_GRAYSCALE and IMREAD_COLOR (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_ecc.cpp missing ReadFlag enum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: perf_ecc.cpp should test both grayscale and color images (fixed version)
if grep -q "testing::Values(IMREAD_GRAYSCALE, IMREAD_COLOR)" modules/video/perf/perf_ecc.cpp; then
    echo "PASS: perf_ecc.cpp tests both grayscale and color (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_ecc.cpp missing color image tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: ecc.cpp should NOT have "8uC1 or 32fC1" restriction (fixed version removes it)
if grep -q "8uC1 or 32fC1" modules/video/src/ecc.cpp; then
    echo "FAIL: ecc.cpp still has 8uC1 or 32fC1 restriction (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: ecc.cpp does not have 8uC1 or 32fC1 restriction (fixed version)"
    checks_passed=$((checks_passed + 1))
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
