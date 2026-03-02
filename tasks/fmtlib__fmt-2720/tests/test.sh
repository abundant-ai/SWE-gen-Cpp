#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/compile-test.cc" "test/compile-test.cc"

test_status=0

# Build the specific test file
cd build
echo "Building compile-test..."
if ! cmake --build . --target compile-test 2>&1; then
    echo "FAIL: compile-test build failed"
    test_status=1
else
    echo "PASS: compile-test built successfully"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
