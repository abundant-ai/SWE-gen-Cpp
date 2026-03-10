#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_file_logging.cpp" "tests/test_file_logging.cpp"

# Build and run tests using CMake
mkdir -p build
cd build
cmake -DSPDLOG_BUILD_TESTS=ON .. 2>&1 || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Build the test executable
cmake --build . --target spdlog-utests 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run tests from test_file_logging.cpp
# Catch2 allows filtering tests - we run all tests from the test file using their tags
./tests/spdlog-utests "[simple_logger],[flush_on],[truncate],[rotating_logger]" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
