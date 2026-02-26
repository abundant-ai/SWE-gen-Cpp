#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/memory_results_gtest.cc" "test/memory_results_gtest.cc"

# Rebuild tests with the updated source files from /tests
cd build
if ! cmake --build . --config Debug -j 1; then
  echo "Build failed" >&2
  test_status=1
else
  # Run the specific test for this PR
  ./test/memory_results_gtest
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
