#!/bin/bash

cd /app/src

# Set environment variables for CTest
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-spec-builders_test.cc" "googlemock/test/gmock-spec-builders_test.cc"
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock_test.cc" "googlemock/test/gmock_test.cc"

# Rebuild the specific test files after copying them from /tests
cd build

# Reconfigure cmake to pick up the test file changes
cmake -Dgtest_build_samples=ON \
      -Dgtest_build_tests=ON \
      -Dgmock_build_tests=ON \
      -DCMAKE_CXX_FLAGS="-DGTEST_HAS_ABSL=1" \
      .. && \
make -j4 gmock-spec-builders_test gmock_test

# Run the specific test executables
./googlemock/gmock-spec-builders_test && \
./googlemock/gmock_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
