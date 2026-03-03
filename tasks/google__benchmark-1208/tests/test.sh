#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
mkdir -p "test"
cp "/tests/fixture_test.cc" "test/fixture_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

# Initialize test_status
test_status=0

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Rebuild the test targets with the fixed files
cmake --build build --config Debug --target benchmark_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark_test"
    test_status=1
fi

cmake --build build --config Debug --target fixture_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build fixture_test"
    test_status=1
fi

cmake --build build --config Debug --target skip_with_error_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build skip_with_error_test"
    test_status=1
fi

# Run the tests only if they built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    ./test/benchmark_test --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "benchmark_test failed"
        test_status=1
    fi

    ./test/fixture_test --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "fixture_test failed"
        test_status=1
    fi

    ./test/skip_with_error_test --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "skip_with_error_test failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
