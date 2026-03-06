#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_arithm.cpp" "modules/core/test/test_arithm.cpp"

# Rebuild the test binary after copying the updated test file
cd build
ninja -j$(nproc) opencv_test_core

# Run the specific test for LUT functionality
# OpenCV test binaries support --gtest_filter to run specific tests
./bin/opencv_test_core --gtest_filter="*LUT*"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
