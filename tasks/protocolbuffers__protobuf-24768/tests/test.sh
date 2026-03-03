#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "python/google/protobuf/internal"
cp "/tests/python/google/protobuf/internal/proto_api_test.py" "python/google/protobuf/internal/proto_api_test.py"

# Check if proto_api.h contains the required API functions
# The bug.patch removes these functions, so they should be missing in BASE and present in HEAD
# Count occurrences: should be 2 DescriptorPool_FromPool (the overload) in HEAD, 1 in BASE
descriptor_pool_from_pool_count=$(grep -c "DescriptorPool_FromPool" python/google/protobuf/proto_api.h || echo "0")
has_descriptor_pool_as_pool=$(grep -c "DescriptorPool_AsPool" python/google/protobuf/proto_api.h || echo "0")

if [ "$descriptor_pool_from_pool_count" -ge 2 ] && [ "$has_descriptor_pool_as_pool" -ge 1 ]; then
  echo "proto_api.h contains required APIs - this is HEAD (fixed) state"
  test_status=0
else
  echo "proto_api.h is missing required APIs - this is BASE (buggy) state"
  echo "DescriptorPool_FromPool count: $descriptor_pool_from_pool_count (expected >= 2)"
  echo "DescriptorPool_AsPool count: $has_descriptor_pool_as_pool (expected >= 1)"
  test_status=1
fi

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
