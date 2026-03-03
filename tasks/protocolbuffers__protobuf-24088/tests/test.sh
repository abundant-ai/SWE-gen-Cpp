#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "rust/test/shared"
cp "/tests/rust/test/shared/accessors_test.rs" "rust/test/shared/accessors_test.rs"

# Run both Rust test targets (cpp and upb kernels)
bazel test //rust/test/shared:accessors_cpp_test //rust/test/shared:accessors_upb_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
