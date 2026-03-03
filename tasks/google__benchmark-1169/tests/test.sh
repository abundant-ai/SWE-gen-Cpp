#!/bin/bash

cd /app/src

# NOTE: Do NOT copy test file - it's modified by the fix.patch itself
# The test file changes are part of the fix (adding delete statements)

# Initialize test_status
test_status=0

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Rebuild the benchmark_gtest test with the fixed files
cmake --build build --config Debug --target benchmark_gtest -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark_gtest"
    test_status=1
fi

# Run the tests only if they built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    # Enable ASan leak detection
    export ASAN_OPTIONS=detect_leaks=1:halt_on_error=1

    ./test/benchmark_gtest --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "benchmark_gtest failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
