#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/repetitions_test.cc" "test/repetitions_test.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"
mkdir -p "test"
cp "/tests/user_counters_thousands_test.cc" "test/user_counters_thousands_test.cc"

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
cmake --build build --config Debug --target complexity_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build complexity_test"
    test_status=1
fi

cmake --build build --config Debug --target repetitions_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build repetitions_test"
    test_status=1
fi

cmake --build build --config Debug --target reporter_output_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build reporter_output_test"
    test_status=1
fi

cmake --build build --config Debug --target user_counters_tabular_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build user_counters_tabular_test"
    test_status=1
fi

cmake --build build --config Debug --target user_counters_thousands_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build user_counters_thousands_test"
    test_status=1
fi

# Run the tests only if they built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    ./test/complexity_test --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "complexity_test failed"
        test_status=1
    fi

    ./test/repetitions_test --benchmark_min_time=0.01 --benchmark_repetitions=3
    if [ $? -ne 0 ]; then
        echo "repetitions_test failed"
        test_status=1
    fi

    ./test/reporter_output_test --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "reporter_output_test failed"
        test_status=1
    fi

    ./test/user_counters_tabular_test --benchmark_counters_tabular=true --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "user_counters_tabular_test failed"
        test_status=1
    fi

    ./test/user_counters_thousands_test --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "user_counters_thousands_test failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
