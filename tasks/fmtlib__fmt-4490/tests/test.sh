#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/mock-allocator.h" "test/mock-allocator.h"

# For this PR, the bug involves basic_memory_buffer not being movable/assignable
# with non-propagating allocators. The test verifies that the fixed allocator-aware
# logic works correctly by running the test cases.
# Rebuild and run the specific test target after copying updated test files
cmake --build build --target format-test && build/bin/format-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
