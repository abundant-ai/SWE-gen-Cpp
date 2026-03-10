#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=8.0.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "editions"
cp "/tests/editions/generated_files_test.cc" "editions/generated_files_test.cc"

# Run only the generated_files_test using Bazel
# --test_output=errors shows test output on failure
# --verbose_failures shows detailed build failure information
bazel test //editions:generated_files_test --test_output=errors --verbose_failures
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
