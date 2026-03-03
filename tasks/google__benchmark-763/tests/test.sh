#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/internal_threading_test.cc" "test/internal_threading_test.cc"

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

# Build the output_test_helper library needed by internal_threading_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target output_test_helper -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build output_test_helper"
        test_status=1
    fi
fi

# Build the internal_threading_test target specifically
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target internal_threading_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build internal_threading_test"
        test_status=1
    fi
fi

# Run the internal_threading_test
if [ $test_status -eq 0 ]; then
    ./build/test/internal_threading_test
    if [ $? -ne 0 ]; then
        echo "internal_threading_test failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
