#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/commandlineflags_gtest.cc" "test/commandlineflags_gtest.cc"

# Initialize test_status
test_status=0

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Rebuild benchmark_main library to pick up changes
cmake --build build --config Debug --target benchmark_main -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark_main library"
    test_status=1
fi

# Build the commandlineflags_gtest target specifically
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target commandlineflags_gtest -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build commandlineflags_gtest"
        test_status=1
    fi
fi

# Run the commandlineflags_gtest
if [ $test_status -eq 0 ]; then
    ./build/test/commandlineflags_gtest
    if [ $? -ne 0 ]; then
        echo "commandlineflags_gtest failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
