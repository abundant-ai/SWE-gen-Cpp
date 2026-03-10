#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/ranges-test.cc" "test/ranges-test.cc"

# Build the specific test using CMake
cd build
cmake --build . --target ranges-test

# Run the ranges-test executable (built in bin/ directory)
./bin/ranges-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
