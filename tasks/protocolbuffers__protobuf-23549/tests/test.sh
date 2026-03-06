#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=7.6.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hpb/backend/upb"
cp "/tests/hpb/backend/upb/interop_test.cc" "hpb/backend/upb/interop_test.cc"

# Run only the interop_test using Bazel
# --test_output=all shows all test output including build errors
# --verbose_failures shows detailed build failure information
bazel test //hpb/backend/upb:interop_test --test_output=all --verbose_failures
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
