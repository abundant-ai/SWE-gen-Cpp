#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=8.0.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "rust/test/shared/utf8"
cp "/tests/rust/test/shared/utf8/utf8_test.rs" "rust/test/shared/utf8/utf8_test.rs"

# Run the utf8 Rust test using Bazel
# Testing only utf8_cpp_test (utf8_test.rs with cpp backend)
# --test_output=errors shows test output on failure
# --verbose_failures shows detailed build failure information
bazel test //rust/test/shared/utf8:utf8_cpp_test --test_output=errors --verbose_failures
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
