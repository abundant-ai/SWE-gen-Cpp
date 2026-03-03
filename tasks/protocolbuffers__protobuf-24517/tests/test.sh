#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "python/google/protobuf/internal/numpy"
cp "/tests/python/google/protobuf/internal/numpy/numpy_test.py" "python/google/protobuf/internal/numpy/numpy_test.py"

# Run the numpy_test (has changes that will fail in BASE state)
bazel test //python/google/protobuf/internal/numpy:numpy_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
