#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_translation_2d_estimator.cpp" "modules/calib3d/test/test_translation_2d_estimator.cpp"

# Reconfigure cmake to pick up the new test files, then rebuild
# Use -j2 to balance speed and memory usage
# Need to rebuild both the calib3d module and the tests to pick up code changes
cd build
cmake -GNinja \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_DOCS=OFF \
    ..

# Build and check for errors - if build fails, the test should fail
ninja -j2 opencv_calib3d opencv_test_calib3d
build_status=$?
if [ $build_status -ne 0 ]; then
    echo "ERROR: Build failed. The code does not compile." >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run only the translation 2d estimator tests
# Using gtest_filter to run tests related to translation 2d estimator
# Capture output to verify tests actually ran
output=$(./bin/opencv_test_calib3d --gtest_filter=*Translation2D* 2>&1)
test_status=$?
echo "$output"

# Check if any tests actually ran (gtest reports "Running N tests" where N > 0)
# If 0 tests ran, the test file doesn't exist (buggy state) - should fail
if echo "$output" | grep -q "Running 0 tests"; then
    echo "ERROR: No tests found matching filter. Test file may not exist." >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
