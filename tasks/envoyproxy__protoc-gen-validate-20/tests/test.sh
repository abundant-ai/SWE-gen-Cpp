#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files if fix has been applied (detected by _IsValid in templates/cc/enum.go)
if grep -q '_IsValid' templates/cc/enum.go 2>/dev/null; then
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
fi

# Verify C++ enum validation is properly implemented
# Buggy: templates use Go-style map lookup (_name[int32(...)], with 'return' statement)
# Fixed: templates use C++ _IsValid function (no return statement in generated code)
echo "Checking if C++ enum validation is properly implemented..." >&2

# Check 1: templates/cc/enum.go should use C++ _IsValid function
if ! grep -q '_IsValid' templates/cc/enum.go; then
  echo "BUGGY: templates/cc/enum.go uses Go-style map lookup instead of C++ _IsValid" >&2
  test_status=1
# Check 2: templates/cc/enum.go should NOT have 'return' in the error statement (C++ style)
elif grep -q 'return {{ err' templates/cc/enum.go; then
  echo "BUGGY: templates/cc/enum.go has 'return' in error statement (Go style)" >&2
  test_status=1
# Check 3: templates/cc/register.go should have EnumT case for inKey function
elif ! grep -q 'case pgs.EnumT:' templates/cc/register.go; then
  echo "BUGGY: EnumT case missing in templates/cc/register.go inKey function" >&2
  test_status=1
# Check 4: harness.cc should include enums.pb.validate.h when fix is applied
elif ! grep -q '#include "tests/harness/cases/enums.pb.validate.h"' tests/harness/cc/harness.cc; then
  echo "BUGGY: Missing enums.pb.validate.h include in tests/harness/cc/harness.cc" >&2
  test_status=1
# Check 5: harness.cc should call X_TESTS_HARNESS_CASES_ENUMS macro for validation
elif ! grep -q 'X_TESTS_HARNESS_CASES_ENUMS(TRY_RETURN_VALIDATE_CALLABLE)' tests/harness/cc/harness.cc; then
  echo "BUGGY: X_TESTS_HARNESS_CASES_ENUMS macro not called in harness.cc" >&2
  test_status=1
else
  echo "FIXED: C++ enum validation is properly implemented" >&2
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
