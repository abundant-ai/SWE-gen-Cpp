#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/basic_test.cc" "test/basic_test.cc"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/diagnostics_test.cc" "test/diagnostics_test.cc"
mkdir -p "test"
cp "/tests/link_main_test.cc" "test/link_main_test.cc"
mkdir -p "test"
cp "/tests/memory_manager_test.cc" "test/memory_manager_test.cc"
mkdir -p "test"
cp "/tests/perf_counters_test.cc" "test/perf_counters_test.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"
mkdir -p "test"
cp "/tests/user_counters_test.cc" "test/user_counters_test.cc"

# Rebuild the project to pick up the copied test files
cmake --build build --config Debug -j 1

# Run the specific tests for this PR with their required flags
./build/test/basic_test --benchmark_min_time=0.01s && \
./build/test/complexity_test --benchmark_min_time=1000000x && \
./build/test/diagnostics_test --benchmark_min_time=0.01s && \
./build/test/link_main_test --benchmark_min_time=0.01s && \
./build/test/memory_manager_test --benchmark_min_time=0.01s && \
./build/test/perf_counters_test --benchmark_min_time=0.01s --benchmark_perf_counters=CYCLES,INSTRUCTIONS && \
./build/test/reporter_output_test --benchmark_min_time=0.01s && \
./build/test/skip_with_error_test --benchmark_min_time=0.01s && \
./build/test/user_counters_tabular_test --benchmark_counters_tabular=true --benchmark_min_time=0.01s && \
./build/test/user_counters_test --benchmark_min_time=0.01s
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
