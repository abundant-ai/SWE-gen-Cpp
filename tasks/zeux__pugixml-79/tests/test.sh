#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_parse.cpp" "tests/test_parse.cpp"

# Rebuild the test suite with the updated test files
make clean && make -j$(nproc)

# Run the test executable (uses Makefile, output is in build directory)
make test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
