#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/ranges-test.cc" "test/ranges-test.cc"

# Rebuild and run the specific test target after copying updated test files
cmake --build build --target ranges-test && build/bin/ranges-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
