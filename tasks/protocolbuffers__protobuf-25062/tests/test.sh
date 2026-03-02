#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/core/src/test/java/com/google/protobuf"
cp "/tests/java/core/src/test/java/com/google/protobuf/LazyFieldLiteTest.java" "java/core/src/test/java/com/google/protobuf/LazyFieldLiteTest.java"
mkdir -p "java/core/src/test/java/com/google/protobuf"
cp "/tests/java/core/src/test/java/com/google/protobuf/LazyFieldTest.java" "java/core/src/test/java/com/google/protobuf/LazyFieldTest.java"

# Clean Bazel cache to ensure changes are picked up
bazel clean --expunge || true

# Run the specific test targets for LazyField tests using Bazel
bazel test //java/core:LazyFieldTest //java/core:LazyFieldLiteTest --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
