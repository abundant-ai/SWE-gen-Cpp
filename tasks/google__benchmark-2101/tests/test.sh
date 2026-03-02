#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_setup_teardown_cb_types_gtest.cc" "test/benchmark_setup_teardown_cb_types_gtest.cc"
mkdir -p "test"
cp "/tests/memory_results_gtest.cc" "test/memory_results_gtest.cc"
mkdir -p "test"
cp "/tests/options_test.cc" "test/options_test.cc"
mkdir -p "test"
cp "/tests/register_benchmark_test.cc" "test/register_benchmark_test.cc"
mkdir -p "test"
cp "/tests/time_unit_gtest.cc" "test/time_unit_gtest.cc"

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
cmake --build build --config Debug --target benchmark_setup_teardown_cb_types_gtest -j 1
cmake --build build --config Debug --target memory_results_gtest -j 1
cmake --build build --config Debug --target options_test -j 1
cmake --build build --config Debug --target register_benchmark_test -j 1
cmake --build build --config Debug --target time_unit_gtest -j 1

# Run all the specific test files
echo "Running tests..."
./build/test/benchmark_setup_teardown_cb_types_gtest && \
./build/test/memory_results_gtest && \
./build/test/options_test && \
./build/test/register_benchmark_test && \
./build/test/time_unit_gtest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
