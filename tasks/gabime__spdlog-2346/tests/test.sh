#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/includes.h" "tests/includes.h"
mkdir -p "tests"
cp "/tests/test_daily_logger.cpp" "tests/test_daily_logger.cpp"
mkdir -p "tests"
cp "/tests/test_errors.cpp" "tests/test_errors.cpp"
mkdir -p "tests"
cp "/tests/test_fmt_helper.cpp" "tests/test_fmt_helper.cpp"
mkdir -p "tests"
cp "/tests/test_pattern_formatter.cpp" "tests/test_pattern_formatter.cpp"

# Build and run tests for specific tags
mkdir -p build
cd build
cmake -DSPDLOG_BUILD_TESTS=ON .. 2>&1 || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

cmake --build . --target spdlog-utests 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run tests for all relevant tags
./tests/spdlog-utests "[daily_logger][rotating_file_sink][daily_file_sink][errors][fmt_helper][pattern_formatter]" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
