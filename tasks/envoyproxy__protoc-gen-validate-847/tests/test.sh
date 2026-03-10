#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
# NOTE: Only copy test files, NOT source files containing the fix!
# This allows NOP to fail (source files remain buggy) and Oracle to pass (with fix applied)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/maps.proto" "tests/harness/cases/maps.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# The test verifies that map key validation support for 'in' and 'not_in' rules is implemented.
#
# In the buggy state (BASE with bug.patch applied):
#   - The MapKeysIn and MapKeysNotIn messages are removed from maps.proto
#   - The validation logic for map keys with 'in' and 'not_in' constraints is removed from templates
#   - Test cases for these validations are removed from cases.go
#
# In the fixed state (BASE + HEAD test files):
#   - The MapKeysIn and MapKeysNotIn messages are added to maps.proto
#   - The validation logic for map keys with 'in' and 'not_in' constraints is added to templates
#   - Test cases for these validations are added to cases.go

echo "Testing if map keys 'in' and 'not_in' validation support is implemented..." >&2

# Check if MapKeysIn and MapKeysNotIn messages exist in maps.proto
if grep -q 'message MapKeysIn' tests/harness/cases/maps.proto 2>/dev/null && \
   grep -q 'message MapKeysNotIn' tests/harness/cases/maps.proto 2>/dev/null; then
    echo "FIXED: MapKeysIn and MapKeysNotIn messages exist in maps.proto" >&2
    has_proto_messages=1
else
    echo "BUGGY: MapKeysIn and MapKeysNotIn messages are missing from maps.proto" >&2
    has_proto_messages=0
fi

# Check if maps.proto uses the 'in' constraint
if grep -q 'in:.*\["foo".*"bar"\]' tests/harness/cases/maps.proto 2>/dev/null || \
   grep -q 'in.*:.*\[.*"foo"' tests/harness/cases/maps.proto 2>/dev/null; then
    echo "FIXED: maps.proto uses 'in' constraint for map keys" >&2
    has_in_constraint=1
else
    echo "BUGGY: maps.proto does not use 'in' constraint for map keys" >&2
    has_in_constraint=0
fi

# Check if maps.proto uses the 'not_in' constraint
if grep -q 'not_in:.*\["foo".*"bar"\]' tests/harness/cases/maps.proto 2>/dev/null || \
   grep -q 'not_in.*:.*\[.*"foo"' tests/harness/cases/maps.proto 2>/dev/null; then
    echo "FIXED: maps.proto uses 'not_in' constraint for map keys" >&2
    has_not_in_constraint=1
else
    echo "BUGGY: maps.proto does not use 'not_in' constraint for map keys" >&2
    has_not_in_constraint=0
fi

# Check if executor/cases.go imports and uses MapKeysIn
if grep -q 'MapKeysIn' tests/harness/executor/cases.go 2>/dev/null; then
    echo "FIXED: executor/cases.go uses MapKeysIn" >&2
    has_executor_in=1
else
    echo "BUGGY: executor/cases.go does not use MapKeysIn" >&2
    has_executor_in=0
fi

# Check if executor/cases.go imports and uses MapKeysNotIn
if grep -q 'MapKeysNotIn' tests/harness/executor/cases.go 2>/dev/null; then
    echo "FIXED: executor/cases.go uses MapKeysNotIn" >&2
    has_executor_not_in=1
else
    echo "BUGGY: executor/cases.go does not use MapKeysNotIn" >&2
    has_executor_not_in=0
fi

# Check if templates/goshared/msg.go has the 'InLookup' and 'NotInLookup' logic for map keys
if grep -q 'InLookup.*map\[.*\]struct{}' templates/goshared/msg.go 2>/dev/null && \
   grep -q 'Rules.Keys.GetString_.*In' templates/goshared/msg.go 2>/dev/null; then
    echo "FIXED: templates/goshared/msg.go has InLookup logic for map keys" >&2
    has_goshared_in=1
else
    echo "BUGGY: templates/goshared/msg.go missing InLookup logic for map keys" >&2
    has_goshared_in=0
fi

if grep -q 'NotInLookup.*map\[.*\]struct{}' templates/goshared/msg.go 2>/dev/null && \
   grep -q 'Rules.Keys.GetString_.*NotIn' templates/goshared/msg.go 2>/dev/null; then
    echo "FIXED: templates/goshared/msg.go has NotInLookup logic for map keys" >&2
    has_goshared_not_in=1
else
    echo "BUGGY: templates/goshared/msg.go missing NotInLookup logic for map keys" >&2
    has_goshared_not_in=0
fi

# Check if templates/cc/msg.go has the 'InLookup' and 'NotInLookup' logic for map keys
if grep -q 'std::set<string>.*InLookup' templates/cc/msg.go 2>/dev/null && \
   grep -q 'Rules.Keys.GetString_.*In' templates/cc/msg.go 2>/dev/null; then
    echo "FIXED: templates/cc/msg.go has InLookup logic for map keys" >&2
    has_cc_in=1
else
    echo "BUGGY: templates/cc/msg.go missing InLookup logic for map keys" >&2
    has_cc_in=0
fi

if grep -q 'std::set<string>.*NotInLookup' templates/cc/msg.go 2>/dev/null && \
   grep -q 'Rules.Keys.GetString_.*NotIn' templates/cc/msg.go 2>/dev/null; then
    echo "FIXED: templates/cc/msg.go has NotInLookup logic for map keys" >&2
    has_cc_not_in=1
else
    echo "BUGGY: templates/cc/msg.go missing NotInLookup logic for map keys" >&2
    has_cc_not_in=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_proto_messages -eq 1 ] && [ $has_in_constraint -eq 1 ] && [ $has_not_in_constraint -eq 1 ] && \
   [ $has_executor_in -eq 1 ] && [ $has_executor_not_in -eq 1 ] && \
   [ $has_goshared_in -eq 1 ] && [ $has_goshared_not_in -eq 1 ] && \
   [ $has_cc_in -eq 1 ] && [ $has_cc_not_in -eq 1 ]; then
    echo "PASS: All map keys 'in' and 'not_in' validation fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some map keys 'in' and 'not_in' validation fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
