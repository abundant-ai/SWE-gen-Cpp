#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "src/google/protobuf"
cp "/tests/src/google/protobuf/generated_enum_util_test.cc" "src/google/protobuf/generated_enum_util_test.cc"

# Run the specific test for generated_enum_util_test using Bazel
bazel test //src/google/protobuf:generated_enum_util_test --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
