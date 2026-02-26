#!/bin/bash

cd /app/src

# Remove conflicting test/format file that interferes with compilation
rm -f test/format

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/compile-test.cc" "test/compile-test.cc"

# Build the specific test target using CMake
cmake --build build --target compile-test

# Run the test executable
./build/bin/compile-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
