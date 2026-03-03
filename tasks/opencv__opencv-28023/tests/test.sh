#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/3d/test"
cp "/tests/modules/3d/test/test_translation2d_estimator.cpp" "modules/3d/test/test_translation2d_estimator.cpp"

# Reconfigure cmake to pick up the new test file, then rebuild
# Use -j2 to balance speed and memory usage
cd build
cmake -GNinja \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_DOCS=OFF \
    ..
ninja -j2 opencv_test_3d

# Run only the translation2d estimator tests (the tests added in this PR)
# Using gtest_filter to run only tests with "EstimateTranslation2D" in their name
# Capture output to verify tests actually ran
output=$(./bin/opencv_test_3d --gtest_filter=*EstimateTranslation2D* 2>&1)
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
