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

# Run the specific tests using ctest
echo "Running tests with ctest..."
cd build
ctest -R "^(benchmark_min_time_flag_iters_test|benchmark_min_time_flag_time_test|benchmark_setup_teardown_test|complexity_test|diagnostics_test|display_aggregates_only_test|donotoptimize_test|filter_test|internal_threading_test|manual_threading_test|memory_manager_test|perf_counters_test|profiler_manager_iterations_test|profiler_manager_test|register_benchmark_test|repetitions_test|report_aggregates_only_test|reporter_output_test|skip_with_error_test|spec_arg_test|spec_arg_verbosity_test|user_counters_tabular_test|user_counters_test|user_counters_thousands_test)$" -VV --output-on-failure
test_status=$?
cd ..

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
