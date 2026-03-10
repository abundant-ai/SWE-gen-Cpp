#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_timestamp.proto" "tests/harness/cases/wkt_timestamp.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# PR #358 fixes timestamp validation when combining "compare to now" constraints with "within" constraint
# The bug: gt_now/lt_now combined with "within" duration are evaluated incorrectly
# The fix: correctly enforce the intersection of these constraints relative to current time

echo "Testing timestamp validation with 'within' constraints..." >&2

# Test 1: Check if TimestampLTNowWithin message exists in proto
echo "Checking if TimestampLTNowWithin message exists in proto..." >&2
if grep -q "TimestampLTNowWithin" tests/harness/cases/wkt_timestamp.proto; then
    echo "PASS: TimestampLTNowWithin message present in proto file" >&2
    has_lt_now_within=1
else
    echo "FAIL: TimestampLTNowWithin message missing in proto file" >&2
    has_lt_now_within=0
fi

# Test 2: Check if TimestampGTNowWithin message exists in proto
echo "Checking if TimestampGTNowWithin message exists in proto..." >&2
if grep -q "TimestampGTNowWithin" tests/harness/cases/wkt_timestamp.proto; then
    echo "PASS: TimestampGTNowWithin message present in proto file" >&2
    has_gt_now_within=1
else
    echo "FAIL: TimestampGTNowWithin message missing in proto file" >&2
    has_gt_now_within=0
fi

# Test 3: Verify the proto definitions have both lt_now/gt_now and within constraints
echo "Checking if proto defines combined constraints..." >&2
if grep -q "lt_now: true, within:" tests/harness/cases/wkt_timestamp.proto && \
   grep -q "gt_now: true, within:" tests/harness/cases/wkt_timestamp.proto; then
    echo "PASS: Proto definitions include combined constraints" >&2
    has_combined_constraints=1
else
    echo "FAIL: Proto definitions missing combined constraints" >&2
    has_combined_constraints=0
fi

# Test 4: Check test cases exist for TimestampLTNowWithin
echo "Checking if test cases exist for TimestampLTNowWithin..." >&2
if grep -q "timestamp - lt now within" tests/harness/executor/cases.go; then
    echo "PASS: Test cases present for TimestampLTNowWithin" >&2
    has_lt_now_within_tests=1
else
    echo "FAIL: Test cases missing for TimestampLTNowWithin" >&2
    has_lt_now_within_tests=0
fi

# Test 5: Check test cases exist for TimestampGTNowWithin
echo "Checking if test cases exist for TimestampGTNowWithin..." >&2
if grep -q "timestamp - gt now within" tests/harness/executor/cases.go; then
    echo "PASS: Test cases present for TimestampGTNowWithin" >&2
    has_gt_now_within_tests=1
else
    echo "FAIL: Test cases missing for TimestampGTNowWithin" >&2
    has_gt_now_within_tests=0
fi

# Test 6: Verify the Go template has correct logic for gt_now with within
echo "Checking Go template for correct gt_now+within logic..." >&2
if grep -A 2 "if \$r.GtNow" templates/goshared/timestamp.go | grep -q 'if ts.Sub(now) <= 0 || ts.Sub(now.Add(within)) > 0'; then
    echo "PASS: Go template has correct logic (ts.Sub(now) <= 0)" >&2
    has_correct_go_logic=1
else
    echo "FAIL: Go template has incorrect logic (should be ts.Sub(now) <= 0)" >&2
    has_correct_go_logic=0
fi

# Test 7: Verify the Python validator has correct logic for gt_now with within
echo "Checking Python validator for correct gt_now+within logic..." >&2
if grep -A 5 "elif ts.HasField('gt_now')" validate/validator.py | grep -q 'if ts <= now or ts >= now + within'; then
    echo "PASS: Python validator has correct logic for gt_now (ts <= now or ts >= now + within)" >&2
    has_correct_py_gt_logic=1
else
    echo "FAIL: Python validator has incorrect logic for gt_now (should be: ts <= now or ts >= now + within)" >&2
    has_correct_py_gt_logic=0
fi

# Test 8: Verify the Python validator has correct logic for lt_now with within
echo "Checking Python validator for correct lt_now+within logic..." >&2
if grep -A 5 "elif ts.HasField('lt_now')" validate/validator.py | grep -q 'if ts >= now or ts <= now - within'; then
    echo "PASS: Python validator has correct logic for lt_now (ts >= now or ts <= now - within)" >&2
    has_correct_py_lt_logic=1
else
    echo "FAIL: Python validator has incorrect logic for lt_now (should be: ts >= now or ts <= now - within)" >&2
    has_correct_py_lt_logic=0
fi

# All checks must pass
if [ $has_lt_now_within -eq 1 ] && [ $has_gt_now_within -eq 1 ] && [ $has_combined_constraints -eq 1 ] && \
   [ $has_lt_now_within_tests -eq 1 ] && [ $has_gt_now_within_tests -eq 1 ] && \
   [ $has_correct_go_logic -eq 1 ] && [ $has_correct_py_gt_logic -eq 1 ] && [ $has_correct_py_lt_logic -eq 1 ]; then
    echo "PASS: All PR #358 fixes are present - timestamp validation with 'within' constraints works correctly" >&2
    test_status=0
else
    echo "FAIL: Some PR #358 fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
