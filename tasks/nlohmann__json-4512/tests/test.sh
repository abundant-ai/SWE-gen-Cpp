#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-iterators3.cpp" "tests/src/unit-iterators3.cpp" || true

# Rebuild the test executable with the updated test file (using C++14 since tests require it)
cmake --build build --target test-iterators3_cpp14 || { echo 0 > /logs/verifier/reward.txt; exit 1; }

# Run the specific test executable
build/tests/test-iterators3_cpp14 2>&1 | tee /tmp/test_output.txt
test_status=${PIPESTATUS[0]}

# Check if tests actually ran (not just an empty test file)
if grep -q "test cases: 0" /tmp/test_output.txt; then
    # Empty test file or tests not enabled - treat as failure
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
