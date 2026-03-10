#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_calibration_hand_eye.cpp" "modules/calib3d/test/test_calibration_hand_eye.cpp"

checks_passed=0
checks_failed=0

# PR #13880 adds hand-eye calibration functionality to OpenCV
# HEAD (bbf39b0964e9246358877b0d72391e9c0b010f0d): Fixed version with calibrateHandEye API
# BASE (after bug.patch): Buggy version without hand-eye calibration feature
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: calibrateHandEye function should exist in calib3d.hpp (fixed version)
if grep -q 'CV_EXPORTS_W void calibrateHandEye' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calibrateHandEye function declared in calib3d.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibrateHandEye function not found in calib3d.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: HandEyeCalibrationMethod enum should exist (fixed version)
if grep -q 'enum HandEyeCalibrationMethod' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: HandEyeCalibrationMethod enum declared in calib3d.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: HandEyeCalibrationMethod enum not found in calib3d.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: calibration_handeye.cpp implementation file should exist (fixed version)
if [ -f modules/calib3d/src/calibration_handeye.cpp ]; then
    echo "PASS: calibration_handeye.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibration_handeye.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_calibration_hand_eye.cpp test file should exist (fixed version)
if [ -f modules/calib3d/test/test_calibration_hand_eye.cpp ]; then
    echo "PASS: test_calibration_hand_eye.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_calibration_hand_eye.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: CALIB_HAND_EYE_TSAI method should be defined (fixed version)
if grep -q 'CALIB_HAND_EYE_TSAI' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: CALIB_HAND_EYE_TSAI method defined (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CALIB_HAND_EYE_TSAI method not defined (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Bibliography entries for hand-eye calibration should exist (fixed version)
if grep -q '@article{Tsai89' doc/opencv.bib; then
    echo "PASS: Tsai89 bibliography entry exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Tsai89 bibliography entry missing (buggy version)" >&2
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
