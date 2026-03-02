#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch fixes handling for missing Duration fields in C++ validation
# Check if the fix has been applied by looking for the non-negated pattern
if grep -q 'if ({{ hasAccessor' templates/cc/duration.go 2>/dev/null && ! grep -q 'if (!{{ hasAccessor' templates/cc/duration.go 2>/dev/null; then
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_duration.proto" "tests/harness/cases/wkt_duration.proto"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
fi

# Verify the C++ Duration validation template handles missing fields correctly
# In buggy state (BASE with bug.patch):
#   - Has early return: "if (!{{ hasAccessor . }}) { return true; }"
#   - When Duration field is missing, returns true immediately (short-circuits entire message validation!)
# In fixed state (HEAD with fix.patch):
#   - Wraps all Duration checks in "if ({{ hasAccessor . }}) {"
#   - When Duration field is missing, simply skips Duration checks but continues with other fields

echo "Checking if C++ Duration template handles missing fields correctly..." >&2

if [ ! -f templates/cc/duration.go ]; then
  echo "ERROR: templates/cc/duration.go not found!" >&2
  test_status=1
else
  # Check if the Duration template has the correct pattern
  # In the BUGGY version: "if (!{{ hasAccessor" appears (returns true when field is missing - short circuits!)
  # In the FIXED version: "if ({{ hasAccessor" appears (wraps checks, doesn't return early)

  # Look for the pattern in the first 35 lines (that's where it should be)
  if head -35 templates/cc/duration.go | grep -q 'if (!{{ hasAccessor'; then
    echo "BUGGY: Found 'if (!hasAccessor) return true' - missing Duration fields cause early return (short-circuit)" >&2
    test_status=1
  elif head -35 templates/cc/duration.go | grep -q 'if ({{ hasAccessor'; then
    echo "FIXED: Found 'if (hasAccessor)' wrapping checks - missing Duration fields allow other validations to continue" >&2
    test_status=0
  else
    echo "ERROR: Unexpected template format" >&2
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
