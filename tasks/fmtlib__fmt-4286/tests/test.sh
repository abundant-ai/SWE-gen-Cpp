#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/std-test.cc" "test/std-test.cc"
mkdir -p "test"
cp "/tests/xchar-test.cc" "test/xchar-test.cc"

# Rebuild and run the specific test targets after copying updated test files
cmake --build build --target std-test && build/bin/std-test && \
cmake --build build --target xchar-test && build/bin/xchar-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
