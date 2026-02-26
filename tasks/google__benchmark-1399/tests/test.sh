#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_name_gtest.cc" "test/benchmark_name_gtest.cc"
mkdir -p "test"
cp "/tests/options_test.cc" "test/options_test.cc"

# Rebuild the tests to pick up the updated test files
echo "Rebuilding benchmark_name_gtest test..."
if cmake --build build --target benchmark_name_gtest --config Debug -j 1 > /tmp/build_name.log 2>&1; then
  echo "✓ benchmark_name_gtest rebuild succeeded"
else
  echo "✗ benchmark_name_gtest rebuild failed"
  cat /tmp/build_name.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

echo "Rebuilding options_test..."
if cmake --build build --target options_test --config Debug -j 1 > /tmp/build_options.log 2>&1; then
  echo "✓ options_test rebuild succeeded"
else
  echo "✗ options_test rebuild failed"
  cat /tmp/build_options.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

# Run the specific GoogleTests
echo "Running benchmark_name_gtest..."
./build/test/benchmark_name_gtest
test_status=$?

if [ $test_status -ne 0 ]; then
  echo "✗ benchmark_name_gtest failed"
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

echo "Running options_test..."
./build/test/options_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
