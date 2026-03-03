#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hpb/backend/cpp"
cp "/tests/hpb/backend/cpp/cpp_test.cc" "hpb/backend/cpp/cpp_test.cc"
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/BUILD" "hpb_generator/tests/BUILD"
mkdir -p "hpb_generator/tests"
cp "/tests/hpb_generator/tests/trivial.proto" "hpb_generator/tests/trivial.proto"

# Run the cpp_test target which contains the test methods for the trivial proto
bazel test //hpb/backend/cpp:cpp_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
