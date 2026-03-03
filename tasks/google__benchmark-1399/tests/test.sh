#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_name_gtest.cc" "test/benchmark_name_gtest.cc"
mkdir -p "test"
cp "/tests/options_test.cc" "test/options_test.cc"

# Initialize test_status
test_status=0

# Rebuild tests with the fixed test files
cd /app/src
cmake --build build --config Debug --target benchmark_name_gtest -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark_name_gtest"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target options_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build options_test"
        test_status=1
    fi
fi

# Run the specific tests for this PR only if both built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build
    ./test/benchmark_name_gtest
    test_status=$?

    if [ $test_status -eq 0 ]; then
        ./test/options_test
        test_status=$?
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
