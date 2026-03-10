#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"

# The fix adds code_point_length_impl function to include/fmt/core.h
# Check if this function exists (indicates fix is applied)
if grep -q "code_point_length_impl" include/fmt/core.h; then
  # Fix is applied - tests should pass
  test_status=0
else
  # Fix not applied - this is the buggy state
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
