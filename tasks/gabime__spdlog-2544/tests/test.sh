#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_fmt_helper.cpp" "tests/test_fmt_helper.cpp"
mkdir -p "tests"
cp "/tests/test_pattern_formatter.cpp" "tests/test_pattern_formatter.cpp"

# Build and run tests for [fmt_helper] and [pattern_formatter] tags
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

./tests/spdlog-utests "[fmt_helper]" "[pattern_formatter]" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
