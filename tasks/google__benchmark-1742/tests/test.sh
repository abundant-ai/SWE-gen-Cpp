#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"

# Rebuild the project to pick up the copied test files
cmake --build build --config Debug -j 1

# Run the specific test for this PR with required flags
./build/test/reporter_output_test --benchmark_min_time=0.01s
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
