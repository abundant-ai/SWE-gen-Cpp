#!/bin/bash

cd /app/src

test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
mkdir -p "test"
cp "/tests/output_test.h" "test/output_test.h"
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/user_counters_test.cc" "test/user_counters_test.cc"

# Rebuild the specific tests affected by the changes
if ! cmake --build build --config Debug -j 1; then
    echo "Build failed after applying HEAD test files" >&2
    test_status=1
else
    # Run the specific test binaries for the changed tests
    ./build/test/benchmark_test
    if [ $? -ne 0 ]; then
        test_status=1
    fi

    ./build/test/reporter_output_test
    if [ $? -ne 0 ]; then
        test_status=1
    fi

    ./build/test/user_counters_test
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
