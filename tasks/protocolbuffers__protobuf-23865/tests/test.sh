#!/bin/bash

cd /app/src

# Environment variables for tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "objectivec/Tests"
cp "/tests/objectivec/Tests/GPBMessageTests+Runtime.m" "objectivec/Tests/GPBMessageTests+Runtime.m"
mkdir -p "objectivec/Tests"
cp "/tests/objectivec/Tests/GPBMessageTests.m" "objectivec/Tests/GPBMessageTests.m"

# Objective-C tests require macOS/Xcode to run properly.
# Since we're on Linux, we validate by checking if the source code matches the test expectations.

# Step 1: Check what the test files expect
echo "Checking test file expectations..."
if grep -q "XCTAssertTrue(\[Message2 instancesRespondToSelector:hasSel\]" objectivec/Tests/GPBMessageTests+Runtime.m; then
    echo "Test files expect: oneof fields HAVE has*/setHas* selectors (XCTAssertTrue)"
    test_expects_fixed=true
elif grep -q "XCTAssertFalse(\[Message2 instancesRespondToSelector:hasSel\]" objectivec/Tests/GPBMessageTests+Runtime.m; then
    echo "Test files expect: oneof fields DON'T have has*/setHas* selectors (XCTAssertFalse)"
    test_expects_fixed=false
else
    echo "ERROR: Cannot determine test expectations"
    test_status=1
fi

# Step 2: Check if source code is fixed or buggy
echo "Checking source code state..."
echo "Debug: field.cc WantsHasProperty function:"
grep -A 2 "^bool FieldGenerator::WantsHasProperty" src/google/protobuf/compiler/objectivec/field.cc
echo ""
echo "Debug: GPBMessage.m GPBFieldHasHas function:"
grep -A 4 "^GPB_INLINE BOOL GPBFieldHasHas" objectivec/GPBMessage.m
echo ""

wants_has_property_impl=$(grep -A 2 "^bool FieldGenerator::WantsHasProperty" src/google/protobuf/compiler/objectivec/field.cc | grep "return")
gpb_field_has_has=$(grep -A 4 "^GPB_INLINE BOOL GPBFieldHasHas" objectivec/GPBMessage.m | grep "return")

source_is_fixed=false
if echo "$wants_has_property_impl" | grep -q "real_containing_oneof()"; then
    echo "Source: BUGGY - field.cc excludes oneof from has property"
elif echo "$wants_has_property_impl" | grep -q "return descriptor_->has_presence()"; then
    echo "Source: FIXED - field.cc includes oneof in has property"
    if echo "$gpb_field_has_has" | grep -q "hasIndex >= 0"; then
        echo "Source: BUGGY - GPBMessage.m has negative index check"
        echo "ERROR: Inconsistent - field.cc fixed but GPBMessage.m buggy"
        test_status=1
    elif echo "$gpb_field_has_has" | grep -q "GPBFieldClearHasIvarOnZero"; then
        echo "Source: FIXED - GPBMessage.m allows oneof"
        source_is_fixed=true
    fi
fi

# Step 3: Determine test outcome based on match between tests and source
if [ "$test_expects_fixed" = "true" ] && [ "$source_is_fixed" = "true" ]; then
    echo "RESULT: Test expectations match fixed source → tests would PASS"
    test_status=0
elif [ "$test_expects_fixed" = "false" ] && [ "$source_is_fixed" = "false" ]; then
    echo "RESULT: Test expectations match buggy source → tests would PASS"
    test_status=0
elif [ "$test_expects_fixed" = "true" ] && [ "$source_is_fixed" = "false" ]; then
    echo "RESULT: Test expects fixed but source is buggy → tests would FAIL"
    test_status=1
elif [ "$test_expects_fixed" = "false" ] && [ "$source_is_fixed" = "true" ]; then
    echo "RESULT: Test expects buggy but source is fixed → tests would FAIL"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
