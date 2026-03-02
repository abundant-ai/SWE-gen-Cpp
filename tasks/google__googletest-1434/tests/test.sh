#!/bin/bash

cd /app/src

# Set environment variables for CTest
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googletest/test"
cp "/tests/googletest/test/gtest-printers_test.cc" "googletest/test/gtest-printers_test.cc"

# Rebuild the specific test files after copying them from /tests
cd build

# Reconfigure cmake to pick up the test file changes
cmake -Dgtest_build_samples=ON \
      -Dgtest_build_tests=ON \
      -Dgmock_build_tests=ON \
      -DCMAKE_CXX_FLAGS="-DGTEST_HAS_ABSL=1" \
      .. && \
make -j4 gtest-printers_test

# Run the specific test executables
./googlemock/gtest/gtest-printers_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
