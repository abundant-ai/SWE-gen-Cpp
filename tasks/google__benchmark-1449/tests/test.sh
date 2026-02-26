#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_gtest.cc" "test/benchmark_gtest.cc"

# Rebuild the test to pick up the updated test file
echo "Rebuilding benchmark_gtest test..."
if cmake --build build --target benchmark_gtest --config Debug -j 1 > /tmp/build.log 2>&1; then
  echo "✓ Test rebuild succeeded"
else
  echo "✗ Test rebuild failed"
  cat /tmp/build.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

# Run the specific GoogleTest
echo "Running benchmark_gtest..."
./build/test/benchmark_gtest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
