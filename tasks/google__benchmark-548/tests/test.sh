#!/bin/bash

cd /app/src

# Initialize test_status
test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/benchmark_gtest.cc" "test/benchmark_gtest.cc"
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/map_test.cc" "test/map_test.cc"
mkdir -p "test"
cp "/tests/multiple_ranges_test.cc" "test/multiple_ranges_test.cc"
mkdir -p "test"
cp "/tests/statistics_gtest.cc" "test/statistics_gtest.cc"

# Fix missing #include <limits> in benchmark_register.h if it exists
# The fix.patch creates this file but is missing the include
if [ -f "src/benchmark_register.h" ]; then
    if ! grep -q "#include <limits>" "src/benchmark_register.h"; then
        sed -i '/#include <vector>/a #include <limits>' "src/benchmark_register.h"
    fi
fi

# Rebuild tests with the updated test files
cmake --build build --config Debug -j 1

# Run the specific test executables that correspond to the modified test files
# These tests verify that Range/Args/Ranges work correctly with int64_t values
build/test/benchmark_test && \
build/test/benchmark_gtest && \
build/test/complexity_test && \
build/test/map_test && \
build/test/multiple_ranges_test && \
build/test/statistics_gtest

test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
