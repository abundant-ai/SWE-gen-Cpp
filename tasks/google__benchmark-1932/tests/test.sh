#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_iters_test.cc" "test/benchmark_min_time_flag_iters_test.cc"
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_time_test.cc" "test/benchmark_min_time_flag_time_test.cc"
mkdir -p "test"
cp "/tests/filter_test.cc" "test/filter_test.cc"
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"

# Rebuild with the fixed test files
echo "Rebuilding with fixed test files..."
rm -rf build
cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build the specific test targets
cmake --build build --config Debug -j 1

# Run the specific tests directly
echo "Running specific tests for PR #1932..."
test_status=0

# Run each test executable
./build/test/benchmark_min_time_flag_iters_test || test_status=$?
./build/test/benchmark_min_time_flag_time_test || test_status=$?
./build/test/filter_test || test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
