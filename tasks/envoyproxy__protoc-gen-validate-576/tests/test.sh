#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/BUILD" "tests/harness/cc/BUILD"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/diamond_test.cc" "tests/harness/cc/diamond_test.cc"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/other.proto" "tests/harness/cc/other.proto"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/polymorphic_test.cc" "tests/harness/cc/polymorphic_test.cc"

# The test verifies that polymorphic validation functionality is properly implemented
#
# In the buggy state (BASE with bug.patch applied):
#   - AbstractCheckMessage method is removed from validate.h
#   - polymorphic_test.cc and other.proto are deleted
#   - BUILD file doesn't have polymorphic_test target
#   - templates/cc/message.go uses direct Validator<T>::CheckMessage instead of polymorphic lookup
#
# In the fixed state (BASE + HEAD test files):
#   - AbstractCheckMessage method exists in BaseValidator class
#   - polymorphic_test.cc and other.proto files exist
#   - BUILD file has polymorphic_test target with proper dependencies
#   - templates/cc/message.go uses BaseValidator::AbstractCheckMessage for polymorphic lookup

echo "Testing if polymorphic validation functionality is properly implemented..." >&2

# Check if validate.h has the AbstractCheckMessage method
if grep -q 'AbstractCheckMessage' validate/validate.h 2>/dev/null; then
    echo "FIXED: AbstractCheckMessage method exists in validate.h" >&2
    has_abstract_check=1
else
    echo "BUGGY: AbstractCheckMessage method is missing from validate.h" >&2
    has_abstract_check=0
fi

# Check if validate.h includes google/protobuf/message.h (needed for polymorphic Message&)
if grep -q '#include "google/protobuf/message.h"' validate/validate.h 2>/dev/null; then
    echo "FIXED: validate.h includes protobuf message header" >&2
    has_protobuf_include=1
else
    echo "BUGGY: validate.h is missing protobuf message header" >&2
    has_protobuf_include=0
fi

# Check if other.proto file exists
if [ -f "tests/harness/cc/other.proto" ]; then
    echo "FIXED: other.proto file exists" >&2
    has_other_proto=1
else
    echo "BUGGY: other.proto file is missing" >&2
    has_other_proto=0
fi

# Check if polymorphic_test.cc file exists
if [ -f "tests/harness/cc/polymorphic_test.cc" ]; then
    echo "FIXED: polymorphic_test.cc file exists" >&2
    has_polymorphic_test=1
else
    echo "BUGGY: polymorphic_test.cc file is missing" >&2
    has_polymorphic_test=0
fi

# Check if BUILD file has polymorphic_test target
if grep -q 'name = "polymorphic_test"' tests/harness/cc/BUILD 2>/dev/null; then
    echo "FIXED: BUILD file has polymorphic_test target" >&2
    has_build_target=1
else
    echo "BUGGY: BUILD file is missing polymorphic_test target" >&2
    has_build_target=0
fi

# Check if BUILD file loads rules_proto (needed for proto_library)
if grep -q 'load("@rules_proto' tests/harness/cc/BUILD 2>/dev/null; then
    echo "FIXED: BUILD file loads rules_proto" >&2
    has_rules_proto_load=1
else
    echo "BUGGY: BUILD file doesn't load rules_proto" >&2
    has_rules_proto_load=0
fi

# Check if templates/cc/message.go uses AbstractCheckMessage
if grep -q 'BaseValidator::AbstractCheckMessage' templates/cc/message.go 2>/dev/null; then
    echo "FIXED: message.go uses BaseValidator::AbstractCheckMessage" >&2
    has_abstract_call=1
else
    echo "BUGGY: message.go doesn't use BaseValidator::AbstractCheckMessage" >&2
    has_abstract_call=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_abstract_check -eq 1 ] && [ $has_protobuf_include -eq 1 ] && [ $has_other_proto -eq 1 ] && \
   [ $has_polymorphic_test -eq 1 ] && [ $has_build_target -eq 1 ] && [ $has_rules_proto_load -eq 1 ] && \
   [ $has_abstract_call -eq 1 ]; then
    echo "PASS: All polymorphic validation functionality is present" >&2
    test_status=0
else
    echo "FAIL: Some polymorphic validation functionality is missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
