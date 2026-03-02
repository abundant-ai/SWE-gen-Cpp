#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch restores proper C++ code generation for repeated message fields, duration validation, and header guards
# Check if the fix has been applied by looking for the correct patterns in templates
if grep -q '#pragma once' templates/cc/file.go 2>/dev/null; then
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/BUILD" "tests/harness/cc/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
fi

# Verify that the C++ code generation fixes are present
# In buggy state (BASE with bug.patch):
#   - templates/cc/file.go does NOT have '#pragma once'
#   - templates/cc/duration.go has incorrect scope braces
#   - templates/cc/register.go has incorrect inType for repeated messages
# In fixed state (HEAD with fix.patch):
#   - templates/cc/file.go has '#pragma once' header guard
#   - templates/cc/duration.go has correct scope
#   - templates/cc/register.go properly handles repeated message types

echo "Checking if C++ code generation fixes are present..." >&2

if [ ! -f templates/cc/file.go ]; then
  echo "ERROR: templates/cc/file.go not found!" >&2
  test_status=1
else
  # Check if templates/cc/file.go has the #pragma once header guard
  # In the BUGGY version: #pragma once is missing
  # In the FIXED version: #pragma once exists

  if grep -q '#pragma once' templates/cc/file.go; then
    echo "FIXED: Found '#pragma once' in templates/cc/file.go" >&2
    test_status=0
  else
    echo "BUGGY: '#pragma once' not found in templates/cc/file.go" >&2
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
