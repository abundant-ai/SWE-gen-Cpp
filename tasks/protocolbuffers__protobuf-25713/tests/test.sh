#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "python/google/protobuf/internal"
cp "/tests/python/google/protobuf/internal/message_test.py" "python/google/protobuf/internal/message_test.py"

# Run the specific Bazel test for message_test
bazel test //python:message_test --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
