#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_gtest.cc" "test/benchmark_gtest.cc"

# Rebuild only the specific test binary for benchmark_gtest
cmake --build build --target benchmark_gtest --config Debug -j 1
build_status=$?

if [ $build_status -ne 0 ]; then
  echo "FAIL: Failed to rebuild benchmark_gtest test" >&2
  test_status=1
else
  # Run the specific test binary
  ./build/test/benchmark_gtest
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
