#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"
mkdir -p "test"
cp "/tests/string_util_gtest.cc" "test/string_util_gtest.cc"
mkdir -p "test"
cp "/tests/user_counters_thousands_test.cc" "test/user_counters_thousands_test.cc"

# Rebuild the project to pick up the copied test files
cmake --build build --config Debug -j 1

# Run the specific tests for this PR
# Note: output_test_helper.cc is a library, not a test executable itself
# string_util_gtest and user_counters_thousands_test are the actual test executables

echo "Running string_util_gtest..."
./build/test/string_util_gtest
gtest_status=$?

echo "Running user_counters_thousands_test..."
./build/test/user_counters_thousands_test --benchmark_min_time=0.01s
benchmark_status=$?

# Both tests must pass
if [ $gtest_status -eq 0 ] && [ $benchmark_status -eq 0 ]; then
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
