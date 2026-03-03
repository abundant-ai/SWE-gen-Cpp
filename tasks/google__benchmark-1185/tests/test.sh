#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_random_interleaving_gtest.cc" "test/benchmark_random_interleaving_gtest.cc"

# Initialize test_status
test_status=0

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Rebuild the benchmark_random_interleaving_gtest test with the fixed files
cmake --build build --config Debug --target benchmark_random_interleaving_gtest -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark_random_interleaving_gtest"
    test_status=1
fi

# Run the tests only if they built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    ./test/benchmark_random_interleaving_gtest --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "benchmark_random_interleaving_gtest failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
