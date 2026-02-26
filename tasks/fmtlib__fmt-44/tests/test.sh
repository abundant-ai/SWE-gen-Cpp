#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/gtest-extra-test.cc" "test/gtest-extra-test.cc"
mkdir -p "test"
cp "/tests/util-test.cc" "test/util-test.cc"

# For this PR, the bug causes compilation errors with MinGW, not runtime errors.
# The test is whether the code compiles successfully with MinGW.
# Rebuild the specific test targets after copying updated test files
cmake --build build --target format-test gtest-extra-test util-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
