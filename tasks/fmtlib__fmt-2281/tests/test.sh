#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"

# Rebuild the tests with the updated test file
cd build
make format-test
test_status=$?

# Run the format-test executable if build succeeded
if [ $test_status -eq 0 ]; then
  ./bin/format-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
