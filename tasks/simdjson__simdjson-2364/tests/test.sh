#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/basictests.cpp" "tests/dom/basictests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_number_tests.cpp" "tests/ondemand/ondemand_number_tests.cpp"

# Rebuild the specific test executables with the updated test files
if ! cmake --build build --target basictests ondemand_number_tests -j=2; then
  test_status=1
else
  # Run the specific test executables
  # Tests will fail in buggy state when SIMDJSON_MINUS_ZERO_AS_FLOAT feature is missing
  ./build/tests/dom/basictests && \
  ./build/tests/ondemand/ondemand_number_tests
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
