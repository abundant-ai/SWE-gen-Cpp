#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cc" "test/test.cc"
mkdir -p "test/www/dir"
cp "/tests/www/dir/test.abcde" "test/www/dir/test.abcde"

# Build and run the test binary
cd test
make test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
