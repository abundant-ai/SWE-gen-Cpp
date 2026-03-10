#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# This test verifies that protoc-gen-validate correctly generates validation code
# for repeated fields of type google.protobuf.Any when item-level any rules use `in` or `not_in`.
#
# In the buggy state (BASE with bug.patch applied):
#   - Template code for generating In/NotIn lookup maps for repeated Any items is removed from templates/cc/msg.go and templates/goshared/msg.go
#   - Test messages RepeatedAnyIn and RepeatedAnyNotIn are removed from tests/harness/cases/repeated.proto
#   - Test cases for RepeatedAnyIn and RepeatedAnyNotIn are removed from tests/harness/executor/cases.go
#
# In the fixed state (BASE + HEAD test files + fix.patch):
#   - Template code exists to generate In/NotIn lookup maps for repeated Any items
#   - Test messages exist in repeated.proto
#   - Test cases exist in cases.go

echo "Testing if protoc-gen-validate generates correct validation for repeated Any fields with in/not_in rules..." >&2

# Check if templates/cc/msg.go has the lookup map generation for Any In rules
if grep -q 'if has .Rules.Items.GetAny "In"' templates/cc/msg.go 2>/dev/null && \
   grep -q 'const std::set<string> {{ lookup .Field "InLookup" }}' templates/cc/msg.go 2>/dev/null; then
    echo "FIXED: C++ template generates In lookup for repeated Any items" >&2
    has_cc_in=1
else
    echo "BUGGY: C++ template missing In lookup for repeated Any items" >&2
    has_cc_in=0
fi

# Check if templates/cc/msg.go has the lookup map generation for Any NotIn rules
if grep -q 'if has .Rules.Items.GetAny "NotIn"' templates/cc/msg.go 2>/dev/null && \
   grep -q 'const std::set<string> {{ lookup .Field "NotInLookup" }}' templates/cc/msg.go 2>/dev/null; then
    echo "FIXED: C++ template generates NotIn lookup for repeated Any items" >&2
    has_cc_notin=1
else
    echo "BUGGY: C++ template missing NotIn lookup for repeated Any items" >&2
    has_cc_notin=0
fi

# Check if templates/goshared/msg.go has the lookup map generation for Any In rules
if grep -q 'if has .Rules.Items.GetAny "In"' templates/goshared/msg.go 2>/dev/null && \
   grep -q 'var {{ lookup .Field "InLookup" }} = map\[string\]struct{}' templates/goshared/msg.go 2>/dev/null; then
    echo "FIXED: Go template generates In lookup for repeated Any items" >&2
    has_go_in=1
else
    echo "BUGGY: Go template missing In lookup for repeated Any items" >&2
    has_go_in=0
fi

# Check if templates/goshared/msg.go has the lookup map generation for Any NotIn rules
if grep -q 'if has .Rules.Items.GetAny "NotIn"' templates/goshared/msg.go 2>/dev/null && \
   grep -q 'var {{ lookup .Field "NotInLookup" }} = map\[string\]struct{}' templates/goshared/msg.go 2>/dev/null; then
    echo "FIXED: Go template generates NotIn lookup for repeated Any items" >&2
    has_go_notin=1
else
    echo "BUGGY: Go template missing NotIn lookup for repeated Any items" >&2
    has_go_notin=0
fi

# Check if tests/harness/cases/repeated.proto has the test messages
if grep -q 'message RepeatedAnyIn' tests/harness/cases/repeated.proto 2>/dev/null && \
   grep -q 'message RepeatedAnyNotIn' tests/harness/cases/repeated.proto 2>/dev/null; then
    echo "FIXED: repeated.proto has RepeatedAnyIn and RepeatedAnyNotIn test messages" >&2
    has_proto_messages=1
else
    echo "BUGGY: repeated.proto missing RepeatedAnyIn or RepeatedAnyNotIn" >&2
    has_proto_messages=0
fi

# Check if tests/harness/cases/repeated.proto imports google/protobuf/any.proto
if grep -q 'import "google/protobuf/any.proto"' tests/harness/cases/repeated.proto 2>/dev/null; then
    echo "FIXED: repeated.proto imports google/protobuf/any.proto" >&2
    has_any_import=1
else
    echo "BUGGY: repeated.proto missing google/protobuf/any.proto import" >&2
    has_any_import=0
fi

# Check if tests/harness/executor/cases.go has the test cases
if grep -q '"repeated - items - invalid (any in)"' tests/harness/executor/cases.go 2>/dev/null && \
   grep -q '"repeated - items - valid (any in)"' tests/harness/executor/cases.go 2>/dev/null && \
   grep -q '"repeated - items - invalid (any not_in)"' tests/harness/executor/cases.go 2>/dev/null && \
   grep -q '"repeated - items - valid (any not_in)"' tests/harness/executor/cases.go 2>/dev/null; then
    echo "FIXED: cases.go has all 4 test cases for repeated Any in/not_in" >&2
    has_test_cases=1
else
    echo "BUGGY: cases.go missing one or more test cases for repeated Any" >&2
    has_test_cases=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_cc_in -eq 1 ] && [ $has_cc_notin -eq 1 ] && \
   [ $has_go_in -eq 1 ] && [ $has_go_notin -eq 1 ] && \
   [ $has_proto_messages -eq 1 ] && [ $has_any_import -eq 1 ] && \
   [ $has_test_cases -eq 1 ]; then
    echo "PASS: All fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
