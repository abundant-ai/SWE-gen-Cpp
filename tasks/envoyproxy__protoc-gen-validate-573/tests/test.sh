#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/embed.proto" "tests/harness/cases/other_package/embed.proto"
mkdir -p "tests/harness/cases/yet_another_package"
cp "/tests/harness/cases/yet_another_package/embed.proto" "tests/harness/cases/yet_another_package/embed.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/strings.proto" "tests/harness/cases/strings.proto"

# This test verifies that protoc-gen-validate correctly handles:
# 1. External enums from other packages (including nested ones like Embed.DoubleEmbed.DoubleEnumerated)
# 2. Oneof string validation (using Value() to strip pointer types)
# 3. C++ polymorphic validator lookup (not directly tested here)
#
# In the buggy state (BASE with bug.patch applied):
#   - enumName function is removed from goshared/register.go
#   - file.go uses hardcoded Parent.Name template instead of enumName function
#   - cType/inType don't use Value() to strip pointer types for oneof fields
#   - Test files are missing EnumExternal2, DoubleEmbed, and StringInOneOf
#
# In the fixed state (BASE + HEAD test files + fix.patch):
#   - enumName function exists and properly builds nested enum names
#   - file.go uses enumName helper function
#   - cType/inType use Value() to handle oneof fields correctly
#   - Test files include all test cases

echo "Testing if protoc-gen-validate properly handles external enums and oneof validation..." >&2

# Check if enumName function exists in templates/goshared/register.go
if grep -q 'func (fns goSharedFuncs) enumName(enum pgs.Enum) string' templates/goshared/register.go 2>/dev/null; then
    echo "FIXED: enumName function exists in goshared/register.go" >&2
    has_enum_name_func=1
else
    echo "BUGGY: enumName function is missing from goshared/register.go" >&2
    has_enum_name_func=0
fi

# Check if file.go uses enumName function (not hardcoded Parent.Name)
if grep -q '{{ enumName (index (externalEnums \$) 0) }}' templates/go/file.go 2>/dev/null; then
    echo "FIXED: file.go uses enumName function" >&2
    has_enum_name_usage=1
else
    echo "BUGGY: file.go doesn't use enumName function" >&2
    has_enum_name_usage=0
fi

# Check if templates/goshared/register.go has enumName in the function map
if grep -q '"enumName".*fns.enumName' templates/goshared/register.go 2>/dev/null; then
    echo "FIXED: enumName is registered in function map" >&2
    has_enum_name_registered=1
else
    echo "BUGGY: enumName is not registered in function map" >&2
    has_enum_name_registered=0
fi

# Check if inType uses Value() to strip pointer types
if grep -q 'return fns.Type(f).Value().String()' templates/goshared/register.go 2>/dev/null; then
    echo "FIXED: inType uses Value() to strip pointer types" >&2
    has_value_strip=1
else
    echo "BUGGY: inType doesn't use Value()" >&2
    has_value_strip=0
fi

# Check if cType uses Value() for C++ template (in templates/cc/register.go)
if grep -q 'return fns.cTypeOfString(fns.Type(t.Field()).Value().String())' templates/cc/register.go 2>/dev/null; then
    echo "FIXED: cType uses Value() to strip pointer types" >&2
    has_c_value_strip=1
else
    echo "BUGGY: cType doesn't use Value()" >&2
    has_c_value_strip=0
fi

# Check if test file has EnumExternal2 (uses doubly-nested enum)
if grep -q 'message EnumExternal2.*DoubleEmbed.DoubleEnumerated' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: enums.proto has EnumExternal2 test case" >&2
    has_enum_external2=1
else
    echo "BUGGY: enums.proto is missing EnumExternal2 test case" >&2
    has_enum_external2=0
fi

# Check if other_package/embed.proto has DoubleEmbed nested message
if grep -q 'message DoubleEmbed' tests/harness/cases/other_package/embed.proto 2>/dev/null; then
    echo "FIXED: embed.proto has DoubleEmbed nested message" >&2
    has_double_embed=1
else
    echo "BUGGY: embed.proto is missing DoubleEmbed" >&2
    has_double_embed=0
fi

# Check if strings.proto has StringInOneOf test case
if grep -q 'message StringInOneOf' tests/harness/cases/strings.proto 2>/dev/null; then
    echo "FIXED: strings.proto has StringInOneOf test case" >&2
    has_string_in_oneof=1
else
    echo "BUGGY: strings.proto is missing StringInOneOf test case" >&2
    has_string_in_oneof=0
fi

# Check if tools.go has //go:build tools constraint (proper format)
if grep -q '//go:build tools' tools.go 2>/dev/null; then
    echo "FIXED: tools.go has proper //go:build constraint" >&2
    has_go_build=1
else
    echo "BUGGY: tools.go is missing //go:build constraint" >&2
    has_go_build=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_enum_name_func -eq 1 ] && [ $has_enum_name_usage -eq 1 ] && [ $has_enum_name_registered -eq 1 ] && \
   [ $has_value_strip -eq 1 ] && [ $has_c_value_strip -eq 1 ] && [ $has_enum_external2 -eq 1 ] && \
   [ $has_double_embed -eq 1 ] && [ $has_string_in_oneof -eq 1 ] && [ $has_go_build -eq 1 ]; then
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
