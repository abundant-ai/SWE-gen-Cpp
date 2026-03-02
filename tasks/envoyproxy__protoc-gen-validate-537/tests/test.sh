#!/bin/bash
set -x
cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/messages.proto" "tests/harness/cases/messages.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/numbers.proto" "tests/harness/cases/numbers.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Rebuild the plugin to pick up any template changes
make build

# Regenerate test cases from proto files
make testcases

# The fix should properly handle SyntheticOneOfFields (proto3 optional) in templates
# With the bug (downgraded protoc-gen-star v0.5.3), SyntheticOneOfFields are not handled
# With the fix (upgraded protoc-gen-star v0.6.0), SyntheticOneOfFields ARE handled
# This means validation code for optional fields should be generated in the fixed version

# Check if validation code for optional message field is generated
# The fixed version should generate validation logic that checks m.Val != nil for SyntheticOneOfFields
if grep -q "if m.Val != nil" tests/harness/cases/go/messages.pb.validate.go 2>/dev/null; then
    optional_validation_found=1
else
    optional_validation_found=0
fi

# Test passes if optional field validation is found (means fix is applied)
if [ $optional_validation_found -eq 1 ]; then
    test_status=0
else
    echo "Test failed - proto3 optional validation not generated"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
