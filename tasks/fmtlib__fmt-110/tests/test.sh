#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/gtest-extra.cc" "test/gtest-extra.cc"
mkdir -p "test"
cp "/tests/gtest-extra.h" "test/gtest-extra.h"

# Rebuild after copying the updated test files
cmake --build build --target gtest-extra-test

# Run the gtest-extra-test binary
./build/test/gtest-extra-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
