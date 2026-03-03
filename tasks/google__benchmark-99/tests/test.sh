#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
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
    # Build the specific test to verify the changes
    if ! cmake --build build --target filter_test -j 1; then
        echo "Build failed - test file changes broke the build" >&2
        test_status=1
    else
        # Run the filter_test executable directly (it has its own main())
        # Pass expected count of benchmarks as argument (16 total: 8 CalculatePiRange + 8 CalculatePi variants)
        # This validates that TestReporter properly overrides the const methods and counts all runs
        if ! ./build/test/filter_test --benchmark_filter=Calculate 16; then
            echo "Test execution failed" >&2
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
