#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"

# Build and run the specific tests
cd build

test_status=0

# Rebuild format-test with the updated test file
if ! make format-test 2>&1; then
    echo "FAIL: format-test build failed"
    test_status=1
elif ! ./bin/format-test; then
    echo "FAIL: format-test failed"
    test_status=1
else
    echo "PASS: format-test passed"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
