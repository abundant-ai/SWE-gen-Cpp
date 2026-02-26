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

# Rebuild tests with the updated source files from /tests
cd build
if ! cmake --build . --config Debug -j 1; then
  echo "Build failed" >&2
  test_status=1
else
  # Run the specific test executables
  # GoogleTest tests can be run directly as executables
  ./test/benchmark_setup_teardown_cb_types_gtest && \
  ./test/memory_results_gtest && \
  ./test/time_unit_gtest && \
  ./test/options_test --benchmark_min_time=0.01s && \
  ./test/register_benchmark_test --benchmark_min_time=0.01s
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
