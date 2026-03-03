#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_iters_test.cc" "test/benchmark_min_time_flag_iters_test.cc"
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_time_test.cc" "test/benchmark_min_time_flag_time_test.cc"
mkdir -p "test"
cp "/tests/min_time_parse_gtest.cc" "test/min_time_parse_gtest.cc"

# Rebuild tests after copying HEAD test files
if ! cmake --build build --target benchmark_min_time_flag_iters_test --config Debug -j 1 || \
   ! cmake --build build --target benchmark_min_time_flag_time_test --config Debug -j 1 || \
   ! cmake --build build --target min_time_parse_gtest --config Debug -j 1; then
    echo "Build failed - test compilation error (expected with BASE state)"
    test_status=1
else
    # Run the specific tests for min_time functionality
    ./build/test/benchmark_min_time_flag_iters_test && \
    ./build/test/benchmark_min_time_flag_time_test && \
    ./build/test/min_time_parse_gtest
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
