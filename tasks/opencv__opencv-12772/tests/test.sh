#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_cameracalibration.cpp" "modules/calib3d/test/test_cameracalibration.cpp"
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_cameracalibration_badarg.cpp" "modules/calib3d/test/test_cameracalibration_badarg.cpp"

checks_passed=0
checks_failed=0

# PR #12772: Add calibrateCameraRO() and cvCalibrateCamera4() for object-releasing calibration
# For harbor testing:
# - HEAD (972bdc45e374e347ec9489bb6802033e5f2ebcbf): Fixed version WITH calibrateCameraRO + cvCalibrateCamera4
# - BASE (after bug.patch): Buggy version WITHOUT calibrateCameraRO or cvCalibrateCamera4
# - FIXED (after oracle applies fix): Back to fixed version WITH calibrateCameraRO + cvCalibrateCamera4

# Check 1: calib3d.hpp SHOULD have calibrateCameraRO function (fixed version has it)
if grep -q 'CV_EXPORTS_AS(calibrateCameraROExtended) double calibrateCameraRO' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has calibrateCameraRO function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing calibrateCameraRO function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: calib3d_c.h SHOULD have cvCalibrateCamera4 C interface (fixed version has it)
if grep -q 'CVAPI(double) cvCalibrateCamera4' modules/calib3d/include/opencv2/calib3d/calib3d_c.h; then
    echo "PASS: calib3d_c.h has cvCalibrateCamera4 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d_c.h missing cvCalibrateCamera4 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: calibration.cpp SHOULD implement calibrateCameraRO (fixed version has it)
if grep -q 'double cv::calibrateCameraRO(InputArrayOfArrays _objectPoints,' modules/calib3d/src/calibration.cpp; then
    echo "PASS: calibration.cpp implements calibrateCameraRO - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibration.cpp missing calibrateCameraRO - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: calibration.cpp SHOULD implement cvCalibrateCamera4 (fixed version has it)
if grep -q 'CV_IMPL double cvCalibrateCamera4' modules/calib3d/src/calibration.cpp; then
    echo "PASS: calibration.cpp implements cvCalibrateCamera4 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibration.cpp missing cvCalibrateCamera4 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Documentation SHOULD reference calibrateCameraRO (fixed version has it)
if grep -q 'cv::calibrateCameraRO' doc/tutorials/calib3d/camera_calibration/camera_calibration.markdown; then
    echo "PASS: Documentation references calibrateCameraRO - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Documentation missing calibrateCameraRO - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Documentation SHOULD mention object-releasing method (fixed version has it)
if grep -q 'object-releasing method' doc/tutorials/calib3d/camera_calibration/camera_calibration.markdown; then
    echo "PASS: Documentation mentions object-releasing method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Documentation missing object-releasing method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Documentation SHOULD reference strobl2011iccv (fixed version has it)
if grep -q 'strobl2011iccv' modules/calib3d/doc/calib3d.bib; then
    echo "PASS: Documentation has strobl2011iccv reference - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Documentation missing strobl2011iccv reference - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_cameracalibration_badarg.cpp SHOULD test cvCalibrateCamera4 (fixed version has it)
if grep -q 'cvCalibrateCamera4' modules/calib3d/test/test_cameracalibration_badarg.cpp; then
    echo "PASS: test_cameracalibration_badarg.cpp tests cvCalibrateCamera4 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_cameracalibration_badarg.cpp missing cvCalibrateCamera4 tests - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: Tutorial compatibility SHOULD be OpenCV 4.0 (fixed version has it)
if grep -q 'OpenCV 4.0' doc/tutorials/calib3d/table_of_content_calib3d.markdown; then
    echo "PASS: Tutorial compatibility is OpenCV 4.0 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Tutorial compatibility not OpenCV 4.0 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: sample calibration.cpp SHOULD use calibrateCameraRO (fixed version has it)
if grep -q 'calibrateCameraRO' samples/cpp/calibration.cpp; then
    echo "PASS: calibration.cpp sample uses calibrateCameraRO - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibration.cpp sample missing calibrateCameraRO - buggy version" >&2
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
