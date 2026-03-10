#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/misc/python/test"
cp "/tests/modules/calib3d/misc/python/test/test_calibration.py" "modules/calib3d/misc/python/test/test_calibration.py"
mkdir -p "modules/dnn/misc/python/test"
cp "/tests/modules/dnn/misc/python/test/test_dnn.py" "modules/dnn/misc/python/test/test_dnn.py"
mkdir -p "modules/features2d/misc/python/test"
cp "/tests/modules/features2d/misc/python/test/test_feature_homography.py" "modules/features2d/misc/python/test/test_feature_homography.py"
mkdir -p "modules/ml/misc/python/test"
cp "/tests/modules/ml/misc/python/test/test_digits.py" "modules/ml/misc/python/test/test_digits.py"
mkdir -p "modules/ml/misc/python/test"
cp "/tests/modules/ml/misc/python/test/test_goodfeatures.py" "modules/ml/misc/python/test/test_goodfeatures.py"
mkdir -p "modules/ml/misc/python/test"
cp "/tests/modules/ml/misc/python/test/test_letter_recog.py" "modules/ml/misc/python/test/test_letter_recog.py"
mkdir -p "modules/objdetect/misc/python/test"
cp "/tests/modules/objdetect/misc/python/test/test_facedetect.py" "modules/objdetect/misc/python/test/test_facedetect.py"
mkdir -p "modules/objdetect/misc/python/test"
cp "/tests/modules/objdetect/misc/python/test/test_peopledetect.py" "modules/objdetect/misc/python/test/test_peopledetect.py"
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/CMakeLists.txt" "modules/python/test/CMakeLists.txt"
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/test.py" "modules/python/test/test.py"
mkdir -p "modules/shape/misc/python/test"
cp "/tests/modules/shape/misc/python/test/test_shape.py" "modules/shape/misc/python/test/test_shape.py"
mkdir -p "modules/stitching/misc/python/test"
cp "/tests/modules/stitching/misc/python/test/test_stitching.py" "modules/stitching/misc/python/test/test_stitching.py"
mkdir -p "modules/video/misc/python/test"
cp "/tests/modules/video/misc/python/test/test_lk_homography.py" "modules/video/misc/python/test/test_lk_homography.py"
mkdir -p "modules/video/misc/python/test"
cp "/tests/modules/video/misc/python/test/test_lk_track.py" "modules/video/misc/python/test/test_lk_track.py"
mkdir -p "modules/videoio/misc/python/test"
cp "/tests/modules/videoio/misc/python/test/test_videoio.py" "modules/videoio/misc/python/test/test_videoio.py"

checks_passed=0
checks_failed=0

# The fix adds support for discovering Python tests from multiple module-provided locations.
# HEAD (a0a1fb5fecdc2c): Has ocv_update_file function, add_subdirectory(test), CMakeLists.txt with test config generation,
#                        complex load_tests function, and tests in module-specific locations
# BASE (after bug.patch): Removes ocv_update_file, add_subdirectory(test), CMakeLists.txt, simplifies load_tests,
#                        moves tests to central location
# FIXED (after fix.patch): Restores all HEAD features for multi-location test discovery

# Check 1: cmake/OpenCVUtils.cmake should have ocv_update_file function
if grep -q 'function(ocv_update_file filepath content)' cmake/OpenCVUtils.cmake; then
    echo "PASS: cmake/OpenCVUtils.cmake has ocv_update_file function (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cmake/OpenCVUtils.cmake doesn't have ocv_update_file function (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: modules/python/CMakeLists.txt should have add_subdirectory(test)
if grep -q 'add_subdirectory(test)' modules/python/CMakeLists.txt; then
    echo "PASS: modules/python/CMakeLists.txt has add_subdirectory(test) (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/python/CMakeLists.txt doesn't have add_subdirectory(test) (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: modules/python/test/CMakeLists.txt should exist
if [ -f modules/python/test/CMakeLists.txt ]; then
    echo "PASS: modules/python/test/CMakeLists.txt exists (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/python/test/CMakeLists.txt doesn't exist (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: modules/python/test/CMakeLists.txt should have OPENCV_PYTHON_TESTS_CONFIG_FILE
if grep -q 'OPENCV_PYTHON_TESTS_CONFIG_FILE' modules/python/test/CMakeLists.txt; then
    echo "PASS: modules/python/test/CMakeLists.txt has test config file generation (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/python/test/CMakeLists.txt doesn't have test config file generation (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: modules/python/test/test.py should have complex load_tests with config file reading
if grep -q 'config_file = .opencv_python_tests.cfg.' modules/python/test/test.py; then
    echo "PASS: modules/python/test/test.py has config file reading (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/python/test/test.py doesn't have config file reading (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: modules/python/test/test.py should have multi-location discovery
if grep -q 'for l in locations:' modules/python/test/test.py; then
    echo "PASS: modules/python/test/test.py has multi-location discovery loop (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/python/test/test.py doesn't have multi-location discovery (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: modules/python/test/test.py should have OPENCV_PYTEST_FILTER support
if grep -q "OPENCV_PYTEST_FILTER" modules/python/test/test.py; then
    echo "PASS: modules/python/test/test.py has OPENCV_PYTEST_FILTER support (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/python/test/test.py doesn't have OPENCV_PYTEST_FILTER support (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Test files should be in module-specific locations (not centralized)
# Check for a few representative test files in their module locations
if [ -f modules/calib3d/misc/python/test/test_calibration.py ]; then
    echo "PASS: test_calibration.py is in module-specific location (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_calibration.py is not in module-specific location (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: modules/dnn/misc/python/test/test_dnn.py should exist
if [ -f modules/dnn/misc/python/test/test_dnn.py ]; then
    echo "PASS: test_dnn.py is in module-specific location (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_dnn.py is not in module-specific location (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: modules/stitching/misc/python/test/test_stitching.py should exist
if [ -f modules/stitching/misc/python/test/test_stitching.py ]; then
    echo "PASS: test_stitching.py is in module-specific location (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_stitching.py is not in module-specific location (BASE version)" >&2
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
