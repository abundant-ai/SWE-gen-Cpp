#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/BUILD" "hpb_generator/tests/BUILD"
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/null_enum.proto" "hpb_generator/tests/null_enum.proto"
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/test_generated.cc" "hpb_generator/tests/test_generated.cc"

# Clean Bazel cache to ensure changes are picked up
bazel clean --expunge || true

# Run the specific test for test_generated_cc_code using Bazel
bazel test //hpb_generator/tests:test_generated_cc_code --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
