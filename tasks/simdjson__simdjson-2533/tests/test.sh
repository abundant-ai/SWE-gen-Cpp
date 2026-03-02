#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/CMakeLists.txt" "tests/ondemand/CMakeLists.txt"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_wildcard_tests.cpp" "tests/ondemand/ondemand_wildcard_tests.cpp"

# Rebuild the entire project to ensure test compiles and links properly
# This is needed because the test file uses functions that may not exist in buggy state
cmake --build build -j=2

# Run the ondemand_wildcard_tests executable
./build/tests/ondemand/ondemand_wildcard_tests
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
