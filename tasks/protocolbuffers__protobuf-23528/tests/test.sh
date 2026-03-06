#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=7.6.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/BUILD" "hpb_generator/tests/BUILD"
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/extension_test.cc" "hpb_generator/tests/extension_test.cc"
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/test_generated.cc" "hpb_generator/tests/test_generated.cc"

# Run only the hpb_generator tests using Bazel
# --test_output=all shows all test output including build errors
# --verbose_failures shows detailed build failure information
# We test both modified tests to ensure the fix works
bazel test //hpb_generator/tests:extension_test //hpb_generator/tests:test_generated_cc_code --test_output=errors --verbose_failures
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
