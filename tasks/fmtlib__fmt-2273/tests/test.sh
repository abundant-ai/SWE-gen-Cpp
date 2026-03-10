#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/gtest-extra-test.cc" "test/gtest-extra-test.cc"
mkdir -p "test"
cp "/tests/os-test.cc" "test/os-test.cc"
mkdir -p "test"
cp "/tests/posix-mock-test.cc" "test/posix-mock-test.cc"

# Rebuild the tests with the updated test files
cd build
make gtest-extra-test os-test posix-mock-test
test_status=$?

# Run the test executables if build succeeded
if [ $test_status -eq 0 ]; then
  ./bin/gtest-extra-test && ./bin/os-test && ./bin/posix-mock-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
