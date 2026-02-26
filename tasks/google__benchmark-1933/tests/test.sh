#!/bin/bash

cd /app/src

# Copy HEAD test files and source files from /tests (overwrites BASE state)
cp "/tests/benchmark_random_interleaving_gtest.cc" "test/benchmark_random_interleaving_gtest.cc"
cp "/tests/benchmark_setup_teardown_test.cc" "test/benchmark_setup_teardown_test.cc"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
cp "/tests/output_test.h" "test/output_test.h"
cp "/tests/register_benchmark_test.cc" "test/register_benchmark_test.cc"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

# Reconfigure CMake to regenerate compile_commands.json
cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
  -DBENCHMARK_ENABLE_TESTING=ON \
  -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
  -DBENCHMARK_ENABLE_WERROR=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Run clang-tidy on the specific files modified in this PR
cd /app/src
clang-tidy \
  -p build \
  --config-file=/app/src/.clang-tidy \
  src/benchmark.cc \
  src/check.cc \
  src/commandlineflags.h \
  src/statistics.cc \
  test/benchmark_random_interleaving_gtest.cc \
  test/benchmark_setup_teardown_test.cc \
  test/benchmark_test.cc \
  test/complexity_test.cc \
  test/output_test.h \
  test/register_benchmark_test.cc \
  test/reporter_output_test.cc \
  test/skip_with_error_test.cc \
  2>&1 | tee /tmp/clang-tidy-output.txt

# Check for the SPECIFIC warnings that this PR is supposed to fix:
# 1. global_force_escape_pointer - avoid-non-const-global-variables
# 2. StatisticsSum, SumSquares, Sqr, Sqrt - avoid-non-const-global-variables
# 3. handler (in check.cc) - avoid-non-const-global-variables or misc-use-anonymous-namespace
# 4. Test file variables with missing const or NOLINT comments
#
# These specific warnings should be GONE after applying the fix.
# Other warnings in these files are pre-existing and not part of this PR.

if grep -E "global_force_escape_pointer.*avoid-non-const-global|StatisticsSum.*avoid-non-const-global|SumSquares.*avoid-non-const-global|Sqr.*avoid-non-const-global|Sqrt.*avoid-non-const-global|src/check.cc.*handler.*avoid-non-const-global|src/check.cc.*handler.*misc-use-anonymous-namespace" /tmp/clang-tidy-output.txt; then
  echo "ERROR: Found warnings that should have been fixed by this PR" >&2
  test_status=1
else
  echo "SUCCESS: All targeted warnings from this PR have been fixed" >&2
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
