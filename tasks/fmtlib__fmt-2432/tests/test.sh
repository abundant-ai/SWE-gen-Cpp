#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/args-test.cc" "test/args-test.cc"

test_status=0

# Build the specific test file
cd build
echo "Building args-test..."
if ! cmake --build . --target args-test 2>&1; then
    echo "FAIL: args-test build failed"
    test_status=1
else
    echo "PASS: args-test built successfully"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
