#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch restores proper C++ code generation for duration validation
# Check if the fix has been applied by looking for C++ syntax patterns in templates
if grep -q 'const pgv::protobuf_wkt::Duration& dur' templates/cc/duration.go 2>/dev/null; then
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_duration.proto" "tests/harness/cases/wkt_duration.proto"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
fi

# Verify that the C++ code generation for duration validation is correct
# In buggy state (BASE with bug.patch):
#   - templates/cc/duration.go uses Go syntax (if d := ...; d != nil, time.Duration, etc.)
#   - templates/cc/register.go uses Go types (time.Duration instead of pgv::protobuf_wkt::Duration)
# In fixed state (HEAD with fix.patch):
#   - templates/cc/duration.go uses C++ syntax (const pgv::protobuf_wkt::Duration&, if (dur ...), etc.)
#   - templates/cc/register.go uses C++ types (pgv::protobuf_wkt::Duration)

echo "Checking if C++ duration validation code generation is correct..." >&2

if [ ! -f templates/cc/duration.go ]; then
  echo "ERROR: templates/cc/duration.go not found!" >&2
  test_status=1
else
  # Check if templates/cc/duration.go has C++ syntax (fixed version)
  # In the BUGGY version: uses Go syntax like "if d := {{ accessor . }}; d != nil"
  # In the FIXED version: uses C++ syntax like "const pgv::protobuf_wkt::Duration& dur"

  if grep -q 'const pgv::protobuf_wkt::Duration& dur' templates/cc/duration.go; then
    echo "FIXED: Found C++ syntax 'const pgv::protobuf_wkt::Duration& dur' in templates/cc/duration.go" >&2
    test_status=0
  else
    echo "BUGGY: C++ syntax not found in templates/cc/duration.go (uses Go syntax instead)" >&2
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
