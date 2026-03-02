#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# No test files to copy - we test the repository state directly
# NOP agent: Tests BASE state (with bug.patch applied) - should have pgv::protobuf_wkt::Any
# Oracle agent: Tests HEAD state (bug.patch NOT applied) - should have google::protobuf::Any

# Check if harness.cc has the correct code
# In buggy state (BASE with bug.patch): uses pgv::protobuf_wkt::Any (namespace doesn't exist)
# In fixed state (HEAD): uses google::protobuf::Any (correct usage)

echo "Checking harness.cc for correct Any usage..." >&2

# Look for the fixed pattern (google::protobuf::Any)
if grep -q "google::protobuf::Any" tests/harness/cc/harness.cc; then
  echo "FIXED: Found google::protobuf::Any usage (correct)" >&2
  test_status=0
else
  # Check for the buggy pattern (pgv::protobuf_wkt::Any)
  if grep -q "pgv::protobuf_wkt::Any" tests/harness/cc/harness.cc; then
    echo "BUGGY: Found pgv::protobuf_wkt::Any usage (namespace doesn't exist - would fail on Windows)" >&2
    test_status=1
  else
    echo "ERROR: Neither pattern found in harness.cc" >&2
    grep "using.*Any" tests/harness/cc/harness.cc >&2 || echo "No 'using.*Any' found" >&2
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
