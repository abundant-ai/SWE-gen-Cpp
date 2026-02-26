#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/display_aggregates_only_test.cc" "test/display_aggregates_only_test.cc"
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"
mkdir -p "test"
cp "/tests/report_aggregates_only_test.cc" "test/report_aggregates_only_test.cc"
mkdir -p "test"
cp "/tests/statistics_gtest.cc" "test/statistics_gtest.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"

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

# Build specific test targets (output_test_helper is a library, not a test)
cmake --build build --config Debug --target display_aggregates_only_test -j 1
cmake --build build --config Debug --target report_aggregates_only_test -j 1
cmake --build build --config Debug --target statistics_gtest -j 1
cmake --build build --config Debug --target user_counters_tabular_test -j 1

# Run the specific tests with required arguments
echo "Running tests..."
./build/test/display_aggregates_only_test --benchmark_min_time=0.01 && \
./build/test/report_aggregates_only_test --benchmark_min_time=0.01 && \
./build/test/statistics_gtest && \
./build/test/user_counters_tabular_test --benchmark_counters_tabular=true --benchmark_min_time=0.01

test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
