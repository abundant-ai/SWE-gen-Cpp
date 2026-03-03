#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_convhull.cpp" "modules/imgproc/test/test_convhull.cpp"

# Rebuild the test binary with the updated test file
cd build
ninja opencv_test_imgproc

# Run only the minAreaRect tests (the tests added in this PR)
# Using gtest_filter to run only tests with "minAreaRect" in their name
./bin/opencv_test_imgproc --gtest_filter=*minAreaRect*
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
