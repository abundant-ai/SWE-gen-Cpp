#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/perf_counters_gtest.cc" "test/perf_counters_gtest.cc"

# Rebuild to compile the updated test file
echo "Rebuilding to verify compilation..."
if cmake --build build --config Debug -j 1 > /tmp/build.log 2>&1; then
  echo "✓ Build succeeded"
else
  echo "✗ Build failed"
  cat /tmp/build.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

# Run the specific test binary for perf_counters_gtest
echo "Running perf_counters_gtest..."
./build/test/perf_counters_gtest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
