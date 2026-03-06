#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=7.6.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "bazel/tests"
cp "/tests/bazel/tests/BUILD" "bazel/tests/BUILD"
mkdir -p "bazel/tests"
cp "/tests/bazel/tests/proto_descriptor_set_test.cc" "bazel/tests/proto_descriptor_set_test.cc"

# Run only the proto_descriptor_set_test using Bazel
# --test_output=all shows all test output including build errors
bazel test //bazel/tests:proto_descriptor_set_test --test_output=all
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
