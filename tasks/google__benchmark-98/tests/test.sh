#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/basic_test.cc" "test/basic_test.cc"
mkdir -p "test"
cp "/tests/filter_test.cc" "test/filter_test.cc"

# Reconfigure CMake with the updated test files
if ! rm -rf build || ! cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_ENABLE_TESTING=ON; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Build the specific tests to verify the changes
    if ! cmake --build build --target basic_test -j 1 || ! cmake --build build --target filter_test -j 1; then
        echo "Build failed - test file changes broke the build" >&2
        test_status=1
    else
        # Run basic_test executable
        if ! ./build/test/basic_test; then
            echo "basic_test execution failed" >&2
            test_status=1
        # Run filter_test executable with expected count of benchmarks (16 total)
        elif ! ./build/test/filter_test --benchmark_filter=Calculate 16; then
            echo "filter_test execution failed" >&2
            test_status=1
        else
            test_status=0
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
