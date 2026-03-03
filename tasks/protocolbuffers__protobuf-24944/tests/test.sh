#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "upb/reflection"
cp "/tests/upb/reflection/reflection_test.cc" "upb/reflection/reflection_test.cc"

# Run the specific test target for reflection_test using Bazel
# Note: We don't clean cache first as it causes long rebuilds
bazel test //upb/reflection:reflection_test --test_output=errors
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
