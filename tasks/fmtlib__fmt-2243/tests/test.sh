#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/compile-test.cc" "test/compile-test.cc"

# Rebuild the tests with the updated test files
cd build
make compile-test
test_status=$?

# Run the test executables if build succeeded
if [ $test_status -eq 0 ]; then
  ./bin/compile-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
