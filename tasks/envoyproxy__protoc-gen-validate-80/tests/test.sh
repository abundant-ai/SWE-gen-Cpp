#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch adds support for bytes.len validation rule
# Check if the fix has been applied by looking for "r.Len" in templates/goshared/bytes.go
if grep -q 'r\.Len' templates/goshared/bytes.go 2>/dev/null; then
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/bytes.proto" "tests/harness/cases/bytes.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/strings.proto" "tests/harness/cases/strings.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/bytes.proto" "tests/kitchensink/bytes.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/string.proto" "tests/kitchensink/string.proto"
fi

# Verify the validation templates support the new len rules for strings and bytes
# In buggy state (BASE with bug.patch):
#   - bytes.len and string.len rules are NOT supported in templates
#   - Pattern (regex) checks occur BEFORE length checks (inefficient)
# In fixed state (HEAD with fix.patch):
#   - bytes.len and string.len rules ARE supported
#   - Length checks occur BEFORE pattern checks (efficient)

echo "Checking if exact-length validation rules are supported in templates..." >&2

if [ ! -f templates/goshared/bytes.go ]; then
  echo "ERROR: templates/goshared/bytes.go not found!" >&2
  test_status=1
else
  # Check if the bytes template supports the new Len rule
  # In the FIXED version: "{{ if or $r.Len" appears at line 6
  # In the BUGGY version: "{{ if $r.Pattern }}" appears at line 6
  if head -10 templates/goshared/bytes.go | grep -q 'if or.*Len'; then
    echo "FIXED: Found 'if or...Len' - supports bytes.len validation rule" >&2
    test_status=0
  elif head -10 templates/goshared/bytes.go | grep -q 'if.*Pattern'; then
    echo "BUGGY: Found 'if...Pattern' first - pattern matching comes before length checks" >&2
    test_status=1
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
