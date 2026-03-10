#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/messages.proto" "tests/harness/cases/messages.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/numbers.proto" "tests/harness/cases/numbers.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# This test verifies that protoc-gen-validate correctly supports proto3 optional fields.
#
# In the buggy state (BASE with bug.patch applied):
#   - main.go does NOT import pluginpb or use FEATURE_PROTO3_OPTIONAL
#   - Templates use .OneOfs (v0.5.3 API, no optional support)
#   - Test messages MessageRequiredButOptional and Int64LTEOptional do NOT exist
#   - Test cases for optional fields do NOT exist in cases.go
#
# In the fixed state (BASE + HEAD test files + fix.patch):
#   - main.go imports pluginpb and uses FEATURE_PROTO3_OPTIONAL
#   - Templates use .RealOneOfs and .SyntheticOneOfFields (v0.6.0 API with optional support)
#   - Test messages for optional fields exist
#   - Test cases for optional fields exist in cases.go

echo "Testing if protoc-gen-validate correctly supports proto3 optional fields..." >&2

# Check if main.go imports pluginpb
if grep -q 'google.golang.org/protobuf/types/pluginpb' main.go 2>/dev/null; then
    echo "FIXED: main.go imports pluginpb" >&2
    has_pluginpb_import=1
else
    echo "BUGGY: main.go does not import pluginpb" >&2
    has_pluginpb_import=0
fi

# Check if main.go uses FEATURE_PROTO3_OPTIONAL
if grep -q 'FEATURE_PROTO3_OPTIONAL' main.go 2>/dev/null; then
    echo "FIXED: main.go uses FEATURE_PROTO3_OPTIONAL" >&2
    has_optional_feature=1
else
    echo "BUGGY: main.go does not use FEATURE_PROTO3_OPTIONAL" >&2
    has_optional_feature=0
fi

# Check if templates/cc/msg.go uses .RealOneOfs (v0.6.0 API)
if grep -q '{{ range .RealOneOfs }}' templates/cc/msg.go 2>/dev/null; then
    echo "FIXED: C++ template uses .RealOneOfs" >&2
    has_cc_realoneofs=1
else
    echo "BUGGY: C++ template does not use .RealOneOfs" >&2
    has_cc_realoneofs=0
fi

# Check if templates/goshared/msg.go uses .RealOneOfs (v0.6.0 API)
if grep -q '{{ range .RealOneOfs }}' templates/goshared/msg.go 2>/dev/null; then
    echo "FIXED: Go template uses .RealOneOfs" >&2
    has_go_realoneofs=1
else
    echo "BUGGY: Go template does not use .RealOneOfs" >&2
    has_go_realoneofs=0
fi

# Check if templates/goshared/msg.go has SyntheticOneOfFields handling (v0.6.0 API)
if grep -q 'SyntheticOneOfFields' templates/goshared/msg.go 2>/dev/null; then
    echo "FIXED: Go template handles SyntheticOneOfFields" >&2
    has_synthetic=1
else
    echo "BUGGY: Go template does not handle SyntheticOneOfFields" >&2
    has_synthetic=0
fi

# Check if templates/java/msg.go uses .RealOneOfs (v0.6.0 API)
if grep -q '{{ range .RealOneOfs }}' templates/java/msg.go 2>/dev/null; then
    echo "FIXED: Java template uses .RealOneOfs" >&2
    has_java_realoneofs=1
else
    echo "BUGGY: Java template does not use .RealOneOfs" >&2
    has_java_realoneofs=0
fi

# Check if tests/harness/cases/messages.proto has MessageRequiredButOptional
if grep -q 'MessageRequiredButOptional' tests/harness/cases/messages.proto 2>/dev/null; then
    echo "FIXED: messages.proto has MessageRequiredButOptional" >&2
    has_msg_optional=1
else
    echo "BUGGY: messages.proto does not have MessageRequiredButOptional" >&2
    has_msg_optional=0
fi

# Check if tests/harness/cases/numbers.proto has Int64LTEOptional
if grep -q 'Int64LTEOptional' tests/harness/cases/numbers.proto 2>/dev/null; then
    echo "FIXED: numbers.proto has Int64LTEOptional" >&2
    has_num_optional=1
else
    echo "BUGGY: numbers.proto does not have Int64LTEOptional" >&2
    has_num_optional=0
fi

# Check if tests/harness/executor/cases.go has test cases for optional fields
if grep -q 'Int64LTEOptional' tests/harness/executor/cases.go 2>/dev/null && \
   grep -q 'MessageRequiredButOptional' tests/harness/executor/cases.go 2>/dev/null; then
    echo "FIXED: cases.go has test cases for optional fields" >&2
    has_optional_tests=1
else
    echo "BUGGY: cases.go does not have test cases for optional fields" >&2
    has_optional_tests=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_pluginpb_import -eq 1 ] && [ $has_optional_feature -eq 1 ] && \
   [ $has_cc_realoneofs -eq 1 ] && [ $has_go_realoneofs -eq 1 ] && \
   [ $has_synthetic -eq 1 ] && [ $has_java_realoneofs -eq 1 ] && \
   [ $has_msg_optional -eq 1 ] && [ $has_num_optional -eq 1 ] && \
   [ $has_optional_tests -eq 1 ]; then
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
