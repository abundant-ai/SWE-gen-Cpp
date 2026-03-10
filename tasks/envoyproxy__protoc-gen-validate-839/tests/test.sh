#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
# NOTE: Only copy test files, NOT source files containing the fix!
# This allows NOP to fail (source files remain buggy) and Oracle to pass (with fix applied)
mkdir -p "tests"
cp "/tests/go.mod" "tests/go.mod"
mkdir -p "tests"
cp "/tests/go.sum" "tests/go.sum"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/embed.proto" "tests/harness/cases/other_package/embed.proto"
mkdir -p "tests/harness/cases/yet_another_package"
cp "/tests/harness/cases/yet_another_package/embed.proto" "tests/harness/cases/yet_another_package/embed.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# The test verifies that enum validation with imports from multiple packages is handled correctly.
#
# In the buggy state (BASE with bug.patch applied):
#   - The EnumExternal3 and RepeatedEnumExternal messages are removed from enums.proto
#   - These messages use enums from both other_package and yet_another_package with validation rules
#   - The generator fails to properly handle import aliases when multiple packages have enums
#   - Templates have logic removed that handles enum imports from multiple packages
#
# In the fixed state (BASE + HEAD test files):
#   - The EnumExternal3 and RepeatedEnumExternal messages are added to enums.proto
#   - The generator correctly handles import aliases for enums from multiple packages (via templates)
#   - Generated Go code compiles without 'undeclared name' errors

echo "Testing if enum validation with multiple package imports is handled correctly..." >&2

# Check if enums.proto has EnumExternal3 message (uses enums from both other_package and yet_another_package)
if grep -q 'message EnumExternal3' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: EnumExternal3 message exists in enums.proto" >&2
    has_enum_external3=1
else
    echo "BUGGY: EnumExternal3 message is missing from enums.proto" >&2
    has_enum_external3=0
fi

# Check if enums.proto uses FooNumber from other_package with validation
if grep -q 'other_package\.Embed\.FooNumber.*foo' tests/harness/cases/enums.proto 2>/dev/null && \
   grep -q 'in:.*\[0.*2\]' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: enums.proto uses other_package.Embed.FooNumber with 'in' validation" >&2
    has_foo_validation=1
else
    echo "BUGGY: enums.proto does not use other_package.Embed.FooNumber with validation" >&2
    has_foo_validation=0
fi

# Check if enums.proto uses BarNumber from yet_another_package with validation
if grep -q 'yet_another_package\.Embed\.BarNumber.*bar' tests/harness/cases/enums.proto 2>/dev/null && \
   grep -q 'not_in:.*\[1\]' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: enums.proto uses yet_another_package.Embed.BarNumber with 'not_in' validation" >&2
    has_bar_validation=1
else
    echo "BUGGY: enums.proto does not use yet_another_package.Embed.BarNumber with validation" >&2
    has_bar_validation=0
fi

# Check if enums.proto has RepeatedEnumExternal message
if grep -q 'message RepeatedEnumExternal' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: RepeatedEnumExternal message exists in enums.proto" >&2
    has_repeated_enum=1
else
    echo "BUGGY: RepeatedEnumExternal message is missing from enums.proto" >&2
    has_repeated_enum=0
fi

# Check if templates/goshared/register.go has the inType function that handles enums from multiple packages
if grep -q 'func.*inType.*Field.*interface' templates/goshared/register.go 2>/dev/null && \
   grep -q 'case pgs.EnumT:' templates/goshared/register.go 2>/dev/null && \
   grep -q 'externalEnums' templates/goshared/register.go 2>/dev/null; then
    echo "FIXED: templates/goshared/register.go has enum import handling logic" >&2
    has_goshared_logic=1
else
    echo "BUGGY: templates/goshared/register.go missing enum import handling logic" >&2
    has_goshared_logic=0
fi

# Check if templates/cc/register.go has the inType function with the EnumT case that was removed in bug.patch
# The bug.patch removes a case pgs.EnumT block from the inType function (lines 298-312)
# When fixed, the inType function should have the enum handling case with PackageName and ::
if grep -A 20 'func.*CCFuncs.*inType' templates/cc/register.go 2>/dev/null | grep -q 'case pgs\.EnumT:'; then
    # Also check for the key logic that was removed: PackageName with ::
    if grep -A 20 'case pgs\.EnumT:' templates/cc/register.go 2>/dev/null | grep -q 'PackageName.*String.*::'; then
        echo "FIXED: templates/cc/register.go has enum import handling logic" >&2
        has_cc_logic=1
    else
        echo "BUGGY: templates/cc/register.go has EnumT case but missing PackageName logic" >&2
        has_cc_logic=0
    fi
else
    echo "BUGGY: templates/cc/register.go missing EnumT case in inType function" >&2
    has_cc_logic=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_enum_external3 -eq 1 ] && [ $has_foo_validation -eq 1 ] && [ $has_bar_validation -eq 1 ] && \
   [ $has_repeated_enum -eq 1 ] && [ $has_goshared_logic -eq 1 ] && [ $has_cc_logic -eq 1 ]; then
    echo "PASS: All enum import handling fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some enum import handling fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
