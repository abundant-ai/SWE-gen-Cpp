#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_iters_test.cc" "test/benchmark_min_time_flag_iters_test.cc"
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_time_test.cc" "test/benchmark_min_time_flag_time_test.cc"
mkdir -p "test"
cp "/tests/benchmark_setup_teardown_test.cc" "test/benchmark_setup_teardown_test.cc"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/diagnostics_test.cc" "test/diagnostics_test.cc"
mkdir -p "test"
cp "/tests/display_aggregates_only_test.cc" "test/display_aggregates_only_test.cc"
mkdir -p "test"
cp "/tests/donotoptimize_test.cc" "test/donotoptimize_test.cc"
mkdir -p "test"
cp "/tests/filter_test.cc" "test/filter_test.cc"
mkdir -p "test"
cp "/tests/internal_threading_test.cc" "test/internal_threading_test.cc"
mkdir -p "test"
cp "/tests/manual_threading_test.cc" "test/manual_threading_test.cc"
mkdir -p "test"
cp "/tests/memory_manager_test.cc" "test/memory_manager_test.cc"
mkdir -p "test"
cp "/tests/perf_counters_test.cc" "test/perf_counters_test.cc"
mkdir -p "test"
cp "/tests/profiler_manager_iterations_test.cc" "test/profiler_manager_iterations_test.cc"
mkdir -p "test"
cp "/tests/profiler_manager_test.cc" "test/profiler_manager_test.cc"
mkdir -p "test"
cp "/tests/register_benchmark_test.cc" "test/register_benchmark_test.cc"
mkdir -p "test"
cp "/tests/repetitions_test.cc" "test/repetitions_test.cc"
mkdir -p "test"
cp "/tests/report_aggregates_only_test.cc" "test/report_aggregates_only_test.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"
mkdir -p "test"
cp "/tests/spec_arg_test.cc" "test/spec_arg_test.cc"
mkdir -p "test"
cp "/tests/spec_arg_verbosity_test.cc" "test/spec_arg_verbosity_test.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"
mkdir -p "test"
cp "/tests/user_counters_test.cc" "test/user_counters_test.cc"
mkdir -p "test"
cp "/tests/user_counters_thousands_test.cc" "test/user_counters_thousands_test.cc"

# Rebuild tests with the updated source files from /tests
cd build
if ! cmake --build . --config Debug -j 1; then
  echo "Build failed" >&2
  test_status=1
else
  # Run a representative subset of tests to verify the fix
  # Some tests require specific arguments - check the test source for requirements
  ./test/filter_test --benchmark_min_time=0.01s && \
  ./test/diagnostics_test --benchmark_min_time=0.01s && \
  ./test/donotoptimize_test && \
  ./test/spec_arg_test --benchmark_filter=BM_NotChosen && \
  ./test/spec_arg_verbosity_test --v=42 && \
  ./test/register_benchmark_test --benchmark_min_time=0.01s
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
