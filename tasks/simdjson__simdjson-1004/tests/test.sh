#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/jsoncheck.cpp" "tests/jsoncheck.cpp"
mkdir -p "tests"
cp "/tests/numberparsingcheck.cpp" "tests/numberparsingcheck.cpp"
mkdir -p "tests"
cp "/tests/parse_many_test.cpp" "tests/parse_many_test.cpp"
mkdir -p "tests"
cp "/tests/stringparsingcheck.cpp" "tests/stringparsingcheck.cpp"

# Rebuild tests with the fixed test files
rm -rf build
cmake_output=$(cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1)
echo "$cmake_output"

# Check for MinGW-related CMake configuration messages that indicate the fix is applied
# The fix adds a message(STATUS "Using SIMDJSON_GOOGLE_BENCHMARKS") in cmake/simdjson-flags.cmake
if ! echo "$cmake_output" | grep -q "Using SIMDJSON_GOOGLE_BENCHMARKS"; then
    echo "ERROR: Expected CMake message 'Using SIMDJSON_GOOGLE_BENCHMARKS' not found. MinGW support changes may not be applied."
    test_status=1
else
    # Build and run the specific test executables that were modified in this PR
    cmake --build build --target basictests numberparsingcheck stringparsingcheck jsoncheck parse_many_test

    # Run the tests
    ctest --test-dir build -R 'basictests|numberparsingcheck|stringparsingcheck|jsoncheck|parse_many_test' --output-on-failure
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
