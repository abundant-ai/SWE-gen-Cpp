#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=7.6.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "src/google/protobuf"
cp "/tests/src/google/protobuf/internal_metadata_locator_test.cc" "src/google/protobuf/internal_metadata_locator_test.cc"

# Run only the internal_metadata_locator_test using Bazel
# --test_output=all shows all test output including build errors
bazel test //src/google/protobuf:internal_metadata_locator_test --test_output=all
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
