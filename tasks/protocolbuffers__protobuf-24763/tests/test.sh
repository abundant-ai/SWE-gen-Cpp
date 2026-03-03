#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "python/google/protobuf/internal"
cp "/tests/python/google/protobuf/internal/message_test.py" "python/google/protobuf/internal/message_test.py"

# Run specific test methods that are affected by the bool-to-int changes
# The bug changes how booleans are handled when assigned to int/enum fields
# We test specific methods: testAssignBoolToEnum, testBoolToRepeatedEnum, testBoolToOneofEnum, testBoolToMapEnum, testBoolToExtensionEnum
bazel test //python:message_test --test_filter="*testAssignBoolToEnum*:*testBoolToRepeatedEnum*:*testBoolToOneofEnum*:*testBoolToMapEnum*:*testBoolToExtensionEnum*" --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
