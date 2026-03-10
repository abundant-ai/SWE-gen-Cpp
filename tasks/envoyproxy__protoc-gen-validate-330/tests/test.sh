#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# PR #330 adds support for repeated enum validation (in/not_in checks)
# The bug: missing enum validation for repeated enums
# The fix: adds AnEnum type and RepeatedEnumIn/RepeatedEnumNotIn messages with test cases

echo "Testing repeated enum validation with in/not_in checks..." >&2

# Test 1: Check if AnEnum exists in proto
echo "Checking if AnEnum exists in proto..." >&2
if grep -q "enum AnEnum" tests/harness/cases/repeated.proto; then
    echo "PASS: AnEnum enum present in proto file" >&2
    has_enum=1
else
    echo "FAIL: AnEnum enum missing in proto file" >&2
    has_enum=0
fi

# Test 2: Check if RepeatedEnumIn message exists
echo "Checking if RepeatedEnumIn message exists in proto..." >&2
if grep -q "RepeatedEnumIn" tests/harness/cases/repeated.proto; then
    echo "PASS: RepeatedEnumIn message present in proto file" >&2
    has_enum_in=1
else
    echo "FAIL: RepeatedEnumIn message missing in proto file" >&2
    has_enum_in=0
fi

# Test 3: Check if RepeatedEnumNotIn message exists
echo "Checking if RepeatedEnumNotIn message exists in proto..." >&2
if grep -q "RepeatedEnumNotIn" tests/harness/cases/repeated.proto; then
    echo "PASS: RepeatedEnumNotIn message present in proto file" >&2
    has_enum_not_in=1
else
    echo "FAIL: RepeatedEnumNotIn message missing in proto file" >&2
    has_enum_not_in=0
fi

# Test 4: Check if test cases exist for RepeatedEnumIn
echo "Checking if test cases exist for RepeatedEnumIn..." >&2
if grep -q "repeated - items - invalid (enum in)" tests/harness/executor/cases.go && \
   grep -q "repeated - items - valid (enum in)" tests/harness/executor/cases.go; then
    echo "PASS: Test cases present for RepeatedEnumIn" >&2
    has_enum_in_tests=1
else
    echo "FAIL: Test cases missing for RepeatedEnumIn" >&2
    has_enum_in_tests=0
fi

# Test 5: Check if test cases exist for RepeatedEnumNotIn
echo "Checking if test cases exist for RepeatedEnumNotIn..." >&2
if grep -q "repeated - items - invalid (enum not_in)" tests/harness/executor/cases.go && \
   grep -q "repeated - items - valid (enum not_in)" tests/harness/executor/cases.go; then
    echo "PASS: Test cases present for RepeatedEnumNotIn" >&2
    has_enum_not_in_tests=1
else
    echo "FAIL: Test cases missing for RepeatedEnumNotIn" >&2
    has_enum_not_in_tests=0
fi

# Test 6: Check if Go template has enum In lookup
echo "Checking if Go template has enum In lookup..." >&2
if grep -A 5 'if has .Rules.Items.GetEnum "In"' templates/goshared/msg.go | grep -q "lookup .Field \"InLookup\""; then
    echo "PASS: Go template has enum In lookup" >&2
    has_go_in_lookup=1
else
    echo "FAIL: Go template missing enum In lookup" >&2
    has_go_in_lookup=0
fi

# Test 7: Check if Go template has enum NotIn lookup
echo "Checking if Go template has enum NotIn lookup..." >&2
if grep -A 5 'if has .Rules.Items.GetEnum "NotIn"' templates/goshared/msg.go | grep -q "lookup .Field \"NotInLookup\""; then
    echo "PASS: Go template has enum NotIn lookup" >&2
    has_go_not_in_lookup=1
else
    echo "FAIL: Go template missing enum NotIn lookup" >&2
    has_go_not_in_lookup=0
fi

# Test 8: Check if C++ template has enum In lookup
echo "Checking if C++ template has enum In lookup..." >&2
if grep -A 5 'if has .Rules.Items.GetEnum "In"' templates/cc/msg.go | grep -q "lookup .Field \"InLookup\""; then
    echo "PASS: C++ template has enum In lookup" >&2
    has_cc_in_lookup=1
else
    echo "FAIL: C++ template missing enum In lookup" >&2
    has_cc_in_lookup=0
fi

# Test 9: Check if C++ template has enum NotIn lookup
echo "Checking if C++ template has enum NotIn lookup..." >&2
if grep -A 5 'if has .Rules.Items.GetEnum "NotIn"' templates/cc/msg.go | grep -q "lookup .Field \"NotInLookup\""; then
    echo "PASS: C++ template has enum NotIn lookup" >&2
    has_cc_not_in_lookup=1
else
    echo "FAIL: C++ template missing enum NotIn lookup" >&2
    has_cc_not_in_lookup=0
fi

# Test 10: Check if register.go has inType for EnumT
echo "Checking if register.go has inType for EnumT..." >&2
if grep -A 5 "case pgs.EnumT:" templates/goshared/register.go | grep -q "f.Type().IsRepeated()"; then
    echo "PASS: register.go has inType for EnumT" >&2
    has_register_enum=1
else
    echo "FAIL: register.go missing inType for EnumT" >&2
    has_register_enum=0
fi

# Test 11: Check if C++ in.go template uses static_cast for enum lookup
echo "Checking if C++ in.go template uses static_cast for enum lookup..." >&2
if grep -q "static_cast<decltype" templates/cc/in.go; then
    echo "PASS: C++ in.go uses static_cast for enum lookup" >&2
    has_cc_static_cast=1
else
    echo "FAIL: C++ in.go missing static_cast for enum lookup" >&2
    has_cc_static_cast=0
fi

# All checks must pass
if [ $has_enum -eq 1 ] && [ $has_enum_in -eq 1 ] && [ $has_enum_not_in -eq 1 ] && \
   [ $has_enum_in_tests -eq 1 ] && [ $has_enum_not_in_tests -eq 1 ] && \
   [ $has_go_in_lookup -eq 1 ] && [ $has_go_not_in_lookup -eq 1 ] && \
   [ $has_cc_in_lookup -eq 1 ] && [ $has_cc_not_in_lookup -eq 1 ] && \
   [ $has_register_enum -eq 1 ] && [ $has_cc_static_cast -eq 1 ]; then
    echo "PASS: All PR #330 fixes are present - repeated enum validation works correctly" >&2
    test_status=0
else
    echo "FAIL: Some PR #330 fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
