#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "bazel/tests"
cp "/tests/bazel/tests/BUILD" "bazel/tests/BUILD"
cp "/tests/bazel/tests/cc_toolchain_tests.bzl" "bazel/tests/cc_toolchain_tests.bzl"
cp "/tests/bazel/tests/A.proto" "bazel/tests/A.proto"

# Clean Bazel cache to pick up any changes from the fix
bazel clean --expunge || true

# Run the specific Bazel test for cc_toolchain
bazel test //bazel/tests:cc_toolchain_test_suite --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
