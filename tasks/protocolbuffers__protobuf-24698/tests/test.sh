#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "rust/test"
cp "/tests/rust/test/bad_names.proto" "rust/test/bad_names.proto"
mkdir -p "rust/test/shared"
cp "/tests/rust/test/shared/bad_names_test.rs" "rust/test/shared/bad_names_test.rs"

# Run the bad_names tests (both cpp and upb variants)
bazel test //rust/test/shared:bad_names_cpp_test //rust/test/shared:bad_names_upb_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
