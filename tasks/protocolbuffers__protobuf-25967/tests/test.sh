#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "rust/test/shared"
cp "/tests/rust/test/shared/BUILD" "rust/test/shared/BUILD"
mkdir -p "rust/test/shared"
cp "/tests/rust/test/shared/message_generics_test.rs" "rust/test/shared/message_generics_test.rs"

# Run the specific tests for message_generics using Bazel
bazel test //rust/test/shared:message_generics_cpp_test //rust/test/shared:message_generics_upb_test --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
