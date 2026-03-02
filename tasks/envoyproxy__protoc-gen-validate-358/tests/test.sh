#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_timestamp.proto" "tests/harness/cases/wkt_timestamp.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Verify that the timestamp validation logic changes are correctly applied
# For NOP: Code is in buggy state (incorrect gt_now within logic >= 0), tests should fail (reward=0)
# For Oracle: solve.sh applies fix.patch, timestamp logic is fixed (<= 0), tests should pass (reward=1)

echo "Checking if timestamp validation logic and test files are correctly restored..."

# Check if the timestamp Go template has the CORRECT logic for gt_now with within
if grep -q 'if ts.Sub(now) <= 0 || ts.Sub(now.Add(within)) > 0 {' templates/goshared/timestamp.go; then
    echo "✓ templates/goshared/timestamp.go has correct timestamp validation logic (<= 0)"
    go_template_correct=0
else
    echo "✗ templates/goshared/timestamp.go has incorrect timestamp validation logic"
    go_template_correct=1
fi

# Check if the test messages TimestampLTNowWithin and TimestampGTNowWithin are PRESENT (restored by HEAD files)
if grep -q 'message TimestampLTNowWithin' tests/harness/cases/wkt_timestamp.proto && \
   grep -q 'message TimestampGTNowWithin' tests/harness/cases/wkt_timestamp.proto; then
    echo "✓ Test messages TimestampLTNowWithin and TimestampGTNowWithin are present in wkt_timestamp.proto"
    proto_messages_present=0
else
    echo "✗ Test messages TimestampLTNowWithin and/or TimestampGTNowWithin missing from wkt_timestamp.proto"
    proto_messages_present=1
fi

# Check if the test cases are PRESENT from cases.go (restored by HEAD files)
if grep -q 'timestamp - lt now within' tests/harness/executor/cases.go && \
   grep -q 'timestamp - gt now within' tests/harness/executor/cases.go; then
    echo "✓ Test cases for lt now within and gt now within are present in cases.go"
    test_cases_present=0
else
    echo "✗ Test cases for lt now within and/or gt now within missing from cases.go"
    test_cases_present=1
fi

# Check if the typo is FIXED in cases.go (HEAD version has "lt now" not "lt - now")
if grep -q 'timestamp - lt now - invalid' tests/harness/executor/cases.go && \
   ! grep -q 'timestamp - lt - now - invalid' tests/harness/executor/cases.go; then
    echo "✓ Test case name has correct format (lt now - invalid, not lt - now)"
    typo_fixed=0
else
    echo "✗ Test case name has typo (lt - now) or missing"
    typo_fixed=1
fi

# Try to rebuild to verify changes work
echo "Attempting to rebuild with updated code..."
if make build 2>&1; then
    echo "✓ Build succeeded with updated code"
    build_success=0
else
    echo "✗ Build failed with current code"
    build_success=1
fi

if [ $go_template_correct -eq 0 ] && [ $proto_messages_present -eq 0 ] && [ $test_cases_present -eq 0 ] && [ $typo_fixed -eq 0 ] && [ $build_success -eq 0 ]; then
    echo "All tests passed!"
    test_status=0
else
    echo "Some tests failed!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
