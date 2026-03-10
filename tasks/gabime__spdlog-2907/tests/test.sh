#!/bin/bash

cd /app/src

mkdir -p "tests"
cp "/tests/includes.h" "tests/includes.h"
mkdir -p "tests"
cp "/tests/test_pattern_formatter.cpp" "tests/test_pattern_formatter.cpp"

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

./tests/spdlog-utests "[pattern_formatter]" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
