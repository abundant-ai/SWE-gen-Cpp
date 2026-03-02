#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files if fix has been applied (detected by hasAccessor in templates/cc/any.go)
if grep -q 'hasAccessor' templates/cc/any.go 2>/dev/null; then
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
fi

# Verify C++ validation for google.protobuf.Any is properly implemented
# Buggy: templates use Go-style validation (GetTypeUrl(), no hasAccessor)
# Fixed: templates use C++ style validation (type_url(), hasAccessor, .find())
echo "Checking if C++ validation for google.protobuf.Any is properly implemented..." >&2

# Check 1: templates/cc/any.go should use C++ style validation (hasAccessor)
if ! grep -q 'hasAccessor' templates/cc/any.go; then
  echo "BUGGY: templates/cc/any.go uses Go style validation instead of C++ style" >&2
  test_status=1
# Check 2: templates/cc/any.go should use .find() method (C++ STL map)
elif ! grep -q '\.find(' templates/cc/any.go; then
  echo "BUGGY: templates/cc/any.go doesn't use C++ STL .find() method" >&2
  test_status=1
# Check 3: templates/cc/register.go should have hasAccessor function
elif ! grep -q 'func hasAccessor' templates/cc/register.go; then
  echo "BUGGY: hasAccessor function missing in templates/cc/register.go" >&2
  test_status=1
# Check 4: templates/cc/message.go should have TODO comment (indicating nested validation not implemented)
elif ! grep -q 'TODO(akonradi) implement nested validation' templates/cc/message.go; then
  echo "BUGGY: templates/cc/message.go missing TODO comment (nested validation may be incorrectly implemented)" >&2
  test_status=1
# Check 5: harness.cc should include wkt_any.pb.validate.h when fix is applied
elif ! grep -q '#include "tests/harness/cases/wkt_any.pb.validate.h"' tests/harness/cc/harness.cc; then
  echo "BUGGY: Missing wkt_any.pb.validate.h include in tests/harness/cc/harness.cc" >&2
  test_status=1
# Check 6: harness.cc should call X_TESTS_HARNESS_CASES_WKT_ANY macro for validation
elif ! grep -q 'X_TESTS_HARNESS_CASES_WKT_ANY(TRY_RETURN_VALIDATE_CALLABLE)' tests/harness/cc/harness.cc; then
  echo "BUGGY: X_TESTS_HARNESS_CASES_WKT_ANY macro not called in harness.cc" >&2
  test_status=1
else
  echo "FIXED: C++ validation for google.protobuf.Any is properly implemented" >&2
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
