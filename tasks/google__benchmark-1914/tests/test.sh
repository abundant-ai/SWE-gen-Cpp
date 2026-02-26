#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/profiler_manager_iterations_test.cc" "test/profiler_manager_iterations_test.cc"

# Rebuild the project to pick up the copied test files
cmake --build build --config Debug -j 1

# Run the specific test for this PR
./build/test/profiler_manager_iterations_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
