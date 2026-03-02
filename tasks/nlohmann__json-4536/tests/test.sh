#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-alt-string.cpp" "tests/src/unit-alt-string.cpp"

# Rebuild the test executable with the updated test file
cmake --build build --target test-alt-string_cpp11

# Run the specific test executable
build/tests/test-alt-string_cpp11
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
