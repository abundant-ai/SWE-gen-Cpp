#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/document_stream_tests.cpp" "tests/document_stream_tests.cpp"

# Rebuild the specific test
cmake --build build --target document_stream_tests

# Run the specific test
./build/tests/document_stream_tests
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
