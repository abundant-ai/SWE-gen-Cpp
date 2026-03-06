#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=7.6.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "src/google/protobuf"
cp "/tests/src/google/protobuf/field_with_arena_test.cc" "src/google/protobuf/field_with_arena_test.cc"

# Rebuild the test target with the updated test file
bazel build //src/google/protobuf:field_with_arena_test

# Run only the field_with_arena_test using Bazel
bazel test //src/google/protobuf:field_with_arena_test --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
