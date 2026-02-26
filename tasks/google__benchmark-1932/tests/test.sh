#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
cp "/tests/benchmark_min_time_flag_iters_test.cc" "test/benchmark_min_time_flag_iters_test.cc"
cp "/tests/benchmark_min_time_flag_time_test.cc" "test/benchmark_min_time_flag_time_test.cc"
cp "/tests/filter_test.cc" "test/filter_test.cc"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"

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
  include/benchmark/benchmark.h \
  src/benchmark_runner.cc \
  src/benchmark_runner.h \
  src/string_util.cc \
  src/sysinfo.cc \
  src/timers.cc \
  test/benchmark_min_time_flag_iters_test.cc \
  test/benchmark_min_time_flag_time_test.cc \
  test/filter_test.cc \
  test/output_test_helper.cc \
  2>&1 | tee /tmp/clang-tidy-output.txt

# Check for the SPECIFIC variables that this PR is supposed to fix:
# From bug.patch, these variable initializations were removed (making them uninitialized):
# - name_field_width (benchmark.h)
# - ret (benchmark_runner.cc - BenchTimeType initialization)
# - p_end (benchmark_runner.cc - used twice in parsing functions)
# - exponent (string_util.cc)
# - local_buff (string_util.cc)
# - pos (sysinfo.cc)
# - ret (sysinfo.cc - pthread affinity)
# - self, previous_affinity (sysinfo.cc)
# - freq (sysinfo.cc)
# - spec (timers.cc - struct timespec for process CPU)
# - ts (timers.cc - struct timespec for thread CPU)
# - tz_len, timestamp_len, offset_minutes (timers.cc)
# - timeinfo (timers.cc)
#
# The fix should restore proper initialization, eliminating warnings about these variables.
# We check if clang-tidy still reports warnings mentioning these specific variables.

if grep -E "'name_field_width'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "benchmark_runner\.cc.*'ret'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "benchmark_runner\.cc.*'p_end'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "string_util\.cc.*'exponent'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "string_util\.cc.*'local_buff'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "sysinfo\.cc.*'pos'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "sysinfo\.cc.*'ret'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "sysinfo\.cc.*'self'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "sysinfo\.cc.*'previous_affinity'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "sysinfo\.cc.*'freq'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "timers\.cc.*'spec'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "timers\.cc.*'ts'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "timers\.cc.*'tz_len'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "timers\.cc.*'timestamp_len'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "timers\.cc.*'offset_minutes'.*cppcoreguidelines" /tmp/clang-tidy-output.txt ||
   grep -E "timers\.cc.*'timeinfo'.*cppcoreguidelines" /tmp/clang-tidy-output.txt; then
  echo "ERROR: Found cppcoreguidelines warnings for variables modified by this PR" >&2
  test_status=1
else
  echo "SUCCESS: No cppcoreguidelines violations for variables modified by this PR" >&2
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
