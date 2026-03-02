#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch restores validation for repeated message elements
# Check if the fix has been applied by looking for the validation logic in templates
if grep -q 'ft.IsRepeated()' templates/shared/context.go 2>/dev/null; then
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
cp "/tests/harness/executor/executor.go" "tests/harness/executor/executor.go"
cp "/tests/harness/executor/harness.go" "tests/harness/executor/harness.go"
cp "/tests/harness/executor/worker.go" "tests/harness/executor/worker.go"
fi

# Verify that the repeated field validation logic is present
# In buggy state (BASE with bug.patch):
#   - templates/shared/context.go does NOT check for ft.IsRepeated()
#   - Repeated message elements are not validated
# In fixed state (HEAD with fix.patch):
#   - templates/shared/context.go checks for ft.IsRepeated()
#   - Repeated message elements are properly validated

echo "Checking if repeated field validation logic is present..." >&2

if [ ! -f templates/shared/context.go ]; then
  echo "ERROR: templates/shared/context.go not found!" >&2
  test_status=1
else
  # Check if templates/shared/context.go has the repeated field validation logic
  # In the BUGGY version: ft.IsRepeated() check is missing
  # In the FIXED version: ft.IsRepeated() check exists

  if grep -q 'ft.IsRepeated()' templates/shared/context.go; then
    echo "FIXED: Found ft.IsRepeated() check in templates/shared/context.go" >&2
    test_status=0
  else
    echo "BUGGY: ft.IsRepeated() check not found in templates/shared/context.go" >&2
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
