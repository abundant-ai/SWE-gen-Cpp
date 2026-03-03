#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "editions"
cp "/tests/editions/edition_defaults_test_utils_test.cc" "editions/edition_defaults_test_utils_test.cc"

# Run the edition_defaults_test_utils test (has expectation changes that will fail in BASE state)
bazel test //editions:edition_defaults_test_utils_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
