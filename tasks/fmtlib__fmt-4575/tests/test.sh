#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/std-test.cc" "test/std-test.cc"

# For this PR, the bug causes compilation errors with std::variant and std::expected formatting
# The test is whether the code compiles successfully with the fixed formatter logic
# Rebuild the specific test target after copying updated test files
cmake --build build --target std-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
