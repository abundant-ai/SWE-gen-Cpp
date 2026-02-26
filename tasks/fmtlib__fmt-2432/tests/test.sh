#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/args-test.cc" "test/args-test.cc"

# Rebuild tests with the updated test files
cmake --build build --target args-test

# Run the specific test executables
./build/bin/args-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
