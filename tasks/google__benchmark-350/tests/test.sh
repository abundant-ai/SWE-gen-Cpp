#!/bin/bash

cd /app/src

test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"

# Rebuild the specific tests affected by the changes
if ! cmake --build build --config Debug -j 1; then
    echo "Build failed after applying HEAD test files" >&2
    test_status=1
else
    # Run the specific test binary for the changed test with required arguments
    ./build/test/user_counters_tabular_test --benchmark_counters_tabular=true --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
