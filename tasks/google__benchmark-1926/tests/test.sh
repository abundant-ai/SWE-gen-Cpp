#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
cp "/tests/BUILD" "test/BUILD"

# Check if the fix is present in the source code
# The fix adds reinterpret_cast at line 1615 in include/benchmark/benchmark.h
# Bug state: char* args_default = arg0_default;
# Fixed state: char* args_default = reinterpret_cast<char*>(arg0_default);

if grep -q "reinterpret_cast<char\*>(arg0_default)" include/benchmark/benchmark.h; then
  echo "SUCCESS: reinterpret_cast is present in benchmark.h (code is fixed)" >&2
  test_status=0
else
  echo "ERROR: reinterpret_cast missing from benchmark.h (code has bug)" >&2
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
