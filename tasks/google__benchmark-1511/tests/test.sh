#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"

# Rebuild tests after copying HEAD test files
if ! cmake --build build --target benchmark_test --config Debug -j 1; then
    echo "Build failed - test compilation error (expected with BASE state)"
    test_status=1
else
    # Run the specific test for this PR
    ./build/test/benchmark_test
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
