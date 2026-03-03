#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_gtest.cc" "test/benchmark_gtest.cc"

# The fix removes inappropriate circular dependencies where internal headers
# include benchmark/benchmark.h. Check that internal headers are properly organized:
#
# In the BUGGY state (BASE):
# - src/internal_macros.h includes "benchmark/benchmark.h" (circular dependency)
# - src/log.h includes "benchmark/benchmark.h" (circular dependency)
# - test/benchmark_gtest.cc does NOT include "benchmark/benchmark.h"
#
# In the FIXED state (HEAD):
# - src/internal_macros.h does NOT include "benchmark/benchmark.h"
# - src/log.h does NOT include "benchmark/benchmark.h"
# - test/benchmark_gtest.cc includes "benchmark/benchmark.h"

# Test 1: Check that internal_macros.h does NOT have circular dependency
if grep -q '#include "benchmark/benchmark.h"' src/internal_macros.h; then
  echo "FAIL: src/internal_macros.h has circular dependency on benchmark/benchmark.h"
  test_status=1
# Test 2: Check that log.h does NOT have circular dependency
elif grep -q '#include "benchmark/benchmark.h"' src/log.h; then
  echo "FAIL: src/log.h has circular dependency on benchmark/benchmark.h"
  test_status=1
# Test 3: Check that test file properly includes benchmark.h
elif ! grep -q '#include "benchmark/benchmark.h"' test/benchmark_gtest.cc; then
  echo "FAIL: test/benchmark_gtest.cc missing proper include of benchmark/benchmark.h"
  test_status=1
else
  # All structural checks passed - now verify it actually compiles and works
  echo "SUCCESS: Code structure is correct (no circular dependencies)"

  # Rebuild only the specific test binary for benchmark_gtest
  cmake --build build --target benchmark_gtest --config Debug -j 1
  build_status=$?

  if [ $build_status -ne 0 ]; then
    echo "FAIL: Failed to rebuild benchmark_gtest test after structural fixes" >&2
    test_status=1
  else
    # Run the specific test binary
    ./build/test/benchmark_gtest
    test_status=$?

    if [ $test_status -eq 0 ]; then
      echo "SUCCESS: All tests passed with proper code structure"
    fi
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
