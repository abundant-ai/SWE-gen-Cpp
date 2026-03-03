#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_gtest.cc" "test/benchmark_gtest.cc"
mkdir -p "test"
cp "/tests/multiple_ranges_test.cc" "test/multiple_ranges_test.cc"
mkdir -p "test"
cp "/tests/options_test.cc" "test/options_test.cc"

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

# Build the benchmark_gtest target specifically
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target benchmark_gtest -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build benchmark_gtest"
        test_status=1
    fi
fi

# Build the multiple_ranges_test target specifically
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target multiple_ranges_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build multiple_ranges_test"
        test_status=1
    fi
fi

# Build the options_test target specifically
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target options_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build options_test"
        test_status=1
    fi
fi

# Run the benchmark_gtest
if [ $test_status -eq 0 ]; then
    ./build/test/benchmark_gtest
    if [ $? -ne 0 ]; then
        echo "benchmark_gtest failed"
        test_status=1
    fi
fi

# Run the multiple_ranges_test
if [ $test_status -eq 0 ]; then
    ./build/test/multiple_ranges_test
    if [ $? -ne 0 ]; then
        echo "multiple_ranges_test failed"
        test_status=1
    fi
fi

# Run the options_test
if [ $test_status -eq 0 ]; then
    ./build/test/options_test
    if [ $? -ne 0 ]; then
        echo "options_test failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
