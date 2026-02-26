#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/printf-test.cc" "test/printf-test.cc"

# Rebuild tests with the updated test files
cmake --build build --target format-test printf-test

# Run the specific test executables
./build/bin/format-test && ./build/bin/printf-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
