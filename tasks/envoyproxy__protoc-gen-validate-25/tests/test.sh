#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files if fix has been applied (detected by MessageValidator in templates/cc/message.go)
if grep -q 'MessageValidator<{{ ctype $f.Type }}>::Check' templates/cc/message.go 2>/dev/null; then
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
fi

# Verify C++ nested message validation implementation
# Buggy: Missing validate.h, nested validation code commented out with TODO
# Fixed: Has validate.h with MessageValidator template, proper C++ nested validation in templates/cc/message.go
echo "Checking if C++ nested message validation is properly implemented..." >&2

# Check 1: validate.h should exist with MessageValidator template
if [ ! -f validate/validate.h ]; then
  echo "BUGGY: validate/validate.h not found!" >&2
  test_status=1
# Check 2: templates/cc/message.go should have the MessageValidator::Check call
elif ! grep -q 'MessageValidator<{{ ctype $f.Type }}>::Check' templates/cc/message.go; then
  echo "BUGGY: Nested message validation not properly implemented in templates/cc/message.go" >&2
  test_status=1
# Check 3: templates/cc/message.go should NOT have the TODO comment (means it's still unimplemented)
elif grep -q 'TODO(akonradi) implement nested validation' templates/cc/message.go; then
  echo "BUGGY: Nested validation still has TODO comment (not implemented)" >&2
  test_status=1
# Check 4: templates/cc/file.go should include validate/validate.h header
elif ! grep -q '#include "validate/validate.h"' templates/cc/file.go; then
  echo "BUGGY: Missing validate/validate.h include in templates/cc/file.go" >&2
  test_status=1
else
  echo "FIXED: C++ nested message validation is properly implemented" >&2
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
