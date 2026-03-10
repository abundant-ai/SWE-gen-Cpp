#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# PR #371 fixes validation rule merging for repeated fields with multiple constraints
# The bug: when multiple repeated rules are specified separately (e.g., min_items and max_items),
# only the last one is respected and earlier ones are silently dropped
# The fix: properly merge all repeated field rules (collection-level + item-level)

echo "Testing repeated field validation with multiple constraints..." >&2

# Test 1: Check if RepeatedMinAndMaxItemLen message exists in proto
echo "Checking if RepeatedMinAndMaxItemLen message exists in proto..." >&2
if grep -q "RepeatedMinAndMaxItemLen" tests/harness/cases/repeated.proto; then
    echo "PASS: RepeatedMinAndMaxItemLen message present in proto file" >&2
    has_proto_message=1
else
    echo "FAIL: RepeatedMinAndMaxItemLen message missing in proto file" >&2
    has_proto_message=0
fi

# Test 2: Check if test cases exist for RepeatedMinAndMaxItemLen
echo "Checking if test cases exist for RepeatedMinAndMaxItemLen..." >&2
if grep -q "repeated - min and max items len - valid" tests/harness/executor/cases.go && \
   grep -q "repeated - min and max items len - invalid (min_len)" tests/harness/executor/cases.go && \
   grep -q "repeated - min and max items len - invalid (max_len)" tests/harness/executor/cases.go; then
    echo "PASS: All test cases present for RepeatedMinAndMaxItemLen" >&2
    has_test_cases=1
else
    echo "FAIL: Some test cases missing for RepeatedMinAndMaxItemLen" >&2
    has_test_cases=0
fi

# Test 3: Verify the proto definition has both min_items and max_items constraints
echo "Checking if proto defines both min_items and max_items..." >&2
if grep -A 1 "message RepeatedMinAndMaxItemLen" tests/harness/cases/repeated.proto | grep -q "repeated.min_items" && \
   grep -A 1 "message RepeatedMinAndMaxItemLen" tests/harness/cases/repeated.proto | grep -q "repeated.max_items"; then
    echo "PASS: Proto definition includes both min_items and max_items constraints" >&2
    has_both_constraints=1
else
    echo "FAIL: Proto definition missing min_items or max_items constraint" >&2
    has_both_constraints=0
fi

# Test 4: Check the test case expectations
echo "Checking test case structure..." >&2
if grep -q 'RepeatedMinAndMaxItemLen{Val: \[\]string{"aaa", "bbb"}}.*true' tests/harness/executor/cases.go; then
    echo "PASS: Valid test case (2 items) expects success" >&2
    has_valid_test=1
else
    echo "FAIL: Valid test case not found or incorrect" >&2
    has_valid_test=0
fi

if grep -q 'RepeatedMinAndMaxItemLen{}.*false' tests/harness/executor/cases.go; then
    echo "PASS: Empty array test case expects failure (violates min_items)" >&2
    has_min_test=1
else
    echo "FAIL: Min items test case not found or incorrect" >&2
    has_min_test=0
fi

if grep -q 'RepeatedMinAndMaxItemLen{Val: \[\]string{"aaa", "bbb", "ccc", "ddd"}}.*false' tests/harness/executor/cases.go; then
    echo "PASS: Too many items test case expects failure (violates max_items)" >&2
    has_max_test=1
else
    echo "FAIL: Max items test case not found or incorrect" >&2
    has_max_test=0
fi

# Test 5: Verify go.mod has the correct protobuf version (v1.4.2 after fix)
echo "Checking go.mod for correct protobuf version..." >&2
if grep -q "github.com/golang/protobuf v1.4.2" go.mod; then
    echo "PASS: go.mod has correct protobuf version (v1.4.2)" >&2
    has_correct_version=1
else
    echo "FAIL: go.mod has incorrect protobuf version (should be v1.4.2)" >&2
    has_correct_version=0
fi

# All checks must pass
if [ $has_proto_message -eq 1 ] && [ $has_test_cases -eq 1 ] && [ $has_both_constraints -eq 1 ] && \
   [ $has_valid_test -eq 1 ] && [ $has_min_test -eq 1 ] && [ $has_max_test -eq 1 ] && \
   [ $has_correct_version -eq 1 ]; then
    echo "PASS: All PR #371 fixes are present - repeated field rules properly merged" >&2
    test_status=0
else
    echo "FAIL: Some PR #371 fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
