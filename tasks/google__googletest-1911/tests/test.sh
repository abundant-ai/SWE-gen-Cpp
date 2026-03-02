#!/bin/bash

cd /app/src

# Set environment variables for CTest
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-nice-strict_test.cc" "googlemock/test/gmock-nice-strict_test.cc"

# Rebuild the specific test file after copying it from /tests
cd build

# Reconfigure cmake to pick up the test that was added back by fix.patch
cmake -Dgtest_build_samples=ON \
      -Dgtest_build_tests=ON \
      -Dgmock_build_tests=ON \
      -DCMAKE_CXX_FLAGS="-w" \
      .. && \
make -j4 gmock-nice-strict_test

# Run the specific test executable
./googlemock/gmock-nice-strict_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
