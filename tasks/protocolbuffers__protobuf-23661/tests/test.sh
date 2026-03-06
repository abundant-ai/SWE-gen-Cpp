#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=7.6.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "rust/test"
cp "/tests/rust/test/BUILD" "rust/test/BUILD"
mkdir -p "rust/test/upb"
cp "/tests/rust/test/upb/BUILD" "rust/test/upb/BUILD"
mkdir -p "rust/test/upb"
cp "/tests/rust/test/upb/generated_descriptors_test.rs" "rust/test/upb/generated_descriptors_test.rs"

# Run only the generated_descriptors_test using Bazel
# --test_output=all shows all test output including build errors
# --verbose_failures shows detailed build failure information
bazel test //rust/test/upb:generated_descriptors_test --test_output=all --verbose_failures
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
