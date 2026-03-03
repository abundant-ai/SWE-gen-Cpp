#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "src/google/protobuf"
cp "/tests/src/google/protobuf/feature_resolver_test.cc" "src/google/protobuf/feature_resolver_test.cc"
mkdir -p "src/google/protobuf/compiler"
cp "/tests/src/google/protobuf/compiler/command_line_interface_unittest.cc" "src/google/protobuf/compiler/command_line_interface_unittest.cc"

# Run the command_line_interface test (has expectation changes that will fail in BASE state)
bazel test //src/google/protobuf/compiler:command_line_interface_unittest --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
