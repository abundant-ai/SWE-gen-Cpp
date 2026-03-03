#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/perf_counters_gtest.cc" "test/perf_counters_gtest.cc"

# Rebuild test after copying HEAD test files
if ! cmake --build build --target perf_counters_gtest --config Debug -j 1; then
    echo "Build failed - test compilation error (expected with BASE state)"
    test_status=1
else
    # Run the specific test for perf_counters functionality
    ./build/test/perf_counters_gtest
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
