#!/bin/bash

cd /app/src

export CI=true

# PR #323 adds support for non-strict header validation using the strict: false option
# The fix adds a HEADER_STRING pattern that rejects only \r, \n, and \0 characters
# This is less strict than HTTP_HEADER_VALUE which follows RFC 7230

echo "Testing PR #323: Non-strict header validation with strict: false" >&2

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/strings.proto" "tests/harness/cases/strings.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Test 1: Check if module/checker.go has the HEADER_STRING pattern
echo "Checking if checker.go defines HEADER_STRING pattern..." >&2
if grep -q 'var headerString.*u0000.*u000A.*u000D' module/checker.go && \
   grep -q 'HEADER_STRING.*&headerString' module/checker.go; then
    echo "PASS: checker.go defines HEADER_STRING pattern for non-strict validation" >&2
    has_header_string=1
else
    echo "FAIL: checker.go missing HEADER_STRING pattern" >&2
    has_header_string=0
fi

# Test 2: Check if checkWellKnownRegex handles strict: false
echo "Checking if checkWellKnownRegex handles non-strict mode..." >&2
if grep -q 'non_strict.*r.Strict.*false' module/checker.go && \
   grep -q 'HTTP_HEADER_NAME.*HTTP_HEADER_VALUE.*non_strict' module/checker.go && \
   grep -q 'HEADER_STRING' module/checker.go; then
    echo "PASS: checkWellKnownRegex supports non-strict mode with HEADER_STRING" >&2
    has_strict_check=1
else
    echo "FAIL: checkWellKnownRegex doesn't handle strict: false properly" >&2
    has_strict_check=0
fi

# Test 3: Check if strings.proto includes the new StringValidHeader test case
echo "Checking if strings.proto has StringValidHeader test..." >&2
if grep -q 'StringValidHeader' tests/harness/cases/strings.proto && \
   grep -q 'well_known_regex.*HTTP_HEADER_VALUE.*strict.*false' tests/harness/cases/strings.proto; then
    echo "PASS: strings.proto includes StringValidHeader with strict: false" >&2
    has_proto_test=1
else
    echo "FAIL: strings.proto missing StringValidHeader test case" >&2
    has_proto_test=0
fi

# Test 4: Check if cases.go includes validation tests for non-strict headers
echo "Checking if cases.go has non-strict header validation tests..." >&2
if grep -q 'StringValidHeader' tests/harness/executor/cases.go && \
   grep -q 'non-strict valid header.*valid.*DEL' tests/harness/executor/cases.go && \
   grep -q 'non-strict valid header.*invalid.*NUL\|CR\|NL' tests/harness/executor/cases.go; then
    echo "PASS: cases.go includes tests for non-strict header validation" >&2
    has_go_tests=1
else
    echo "FAIL: cases.go missing non-strict header validation tests" >&2
    has_go_tests=0
fi

# All checks must pass
if [ $has_header_string -eq 1 ] && [ $has_strict_check -eq 1 ] && \
   [ $has_proto_test -eq 1 ] && [ $has_go_tests -eq 1 ]; then
    echo "PASS: All PR #323 fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some PR #323 fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
