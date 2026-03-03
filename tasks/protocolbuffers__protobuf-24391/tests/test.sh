#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "upb/message"
cp "/tests/upb/message/copy_test.cc" "upb/message/copy_test.cc"
mkdir -p "upb/message/internal"
cp "/tests/upb/message/internal/compare_unknown_test.cc" "upb/message/internal/compare_unknown_test.cc"

# Run the specific test files (copy_test and compare_unknown_test)
bazel test //upb/message:copy_test //upb/message:compare_unknown_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
