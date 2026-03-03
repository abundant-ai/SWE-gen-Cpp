#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "rust/test/cpp/interop"
cp "/tests/rust/test/cpp/interop/BUILD" "rust/test/cpp/interop/BUILD"
mkdir -p "rust/test/cpp/interop"
cp "/tests/rust/test/cpp/interop/main.rs" "rust/test/cpp/interop/main.rs"
mkdir -p "rust/test/cpp/interop"
cp "/tests/rust/test/cpp/interop/test_utils.cc" "rust/test/cpp/interop/test_utils.cc"

# Run the Rust test target for cpp interop
bazel test //rust/test/cpp/interop:interop_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
