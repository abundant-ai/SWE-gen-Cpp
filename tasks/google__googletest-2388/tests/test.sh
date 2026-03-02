#!/bin/bash

cd /app/src

# Set environment variables for CTest
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googletest/test"
cp "/tests/googletest/test/gtest-unittest-api_test.cc" "googletest/test/gtest-unittest-api_test.cc"

# Rebuild the specific test file after copying it from /tests
cd build

# Remove the test executable to force rebuild with new flags
rm -f googletest/gtest-unittest-api_test

# Rebuild with -Wdeprecated -Werror to catch deprecated usage
cmake -DCMAKE_CXX_FLAGS="-std=c++11 -Wdeprecated -Werror" .. && \
make -j4 gtest-unittest-api_test

# Run the specific test executable
./googletest/gtest-unittest-api_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
