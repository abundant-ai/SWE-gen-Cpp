#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases/yet_another_package"
cp "/tests/harness/cases/yet_another_package/BUILD" "tests/harness/cases/yet_another_package/BUILD"
mkdir -p "tests/harness/cases/yet_another_package"
cp "/tests/harness/cases/yet_another_package/embed.proto" "tests/harness/cases/yet_another_package/embed.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/harness/go/main"
cp "/tests/harness/go/main/BUILD" "tests/harness/go/main/BUILD"
mkdir -p "tests/harness/go/main"
cp "/tests/harness/go/main/harness.go" "tests/harness/go/main/harness.go"

# This test verifies that the build system correctly includes yet_another_package.
#
# In the buggy state (BASE with bug.patch applied):
#   - .gitignore does NOT have yet_another_package entries
#   - Makefile does NOT have yet_another_package build steps
#   - pom.xml does NOT include yet_another_package protos
#   - BUILD file does NOT depend on yet_another_package targets
#   - enums.proto does NOT import yet_another_package/embed.proto
#   - cases.go does NOT have test cases for yet_another_package enums
#
# In the fixed state (BASE + HEAD test files + fix.patch):
#   - .gitignore has yet_another_package entries
#   - Makefile has yet_another_package build steps
#   - pom.xml includes yet_another_package protos
#   - BUILD file depends on yet_another_package targets
#   - enums.proto imports yet_another_package/embed.proto
#   - cases.go has test cases for RepeatedYetAnotherExternalEnumDefined

echo "Testing if yet_another_package is correctly integrated into build system..." >&2

# Check if .gitignore has yet_another_package entries
if grep -q 'yet_another_package/go' .gitignore 2>/dev/null; then
    echo "FIXED: .gitignore includes yet_another_package" >&2
    has_gitignore=1
else
    echo "BUGGY: .gitignore does not include yet_another_package" >&2
    has_gitignore=0
fi

# Check if Makefile has yet_another_package build steps
if grep -q 'yet_another_package' Makefile 2>/dev/null; then
    echo "FIXED: Makefile includes yet_another_package" >&2
    has_makefile=1
else
    echo "BUGGY: Makefile does not include yet_another_package" >&2
    has_makefile=0
fi

# Check if pom.xml includes yet_another_package
if grep -q 'yet_another_package' java/pgv-java-validation/pom.xml 2>/dev/null; then
    echo "FIXED: pom.xml includes yet_another_package" >&2
    has_pom=1
else
    echo "BUGGY: pom.xml does not include yet_another_package" >&2
    has_pom=0
fi

# Check if Java BUILD file depends on yet_another_package
if grep -q 'yet_another_package' java/pgv-java-validation/src/main/java/io/envoyproxy/pgv/validation/BUILD 2>/dev/null; then
    echo "FIXED: Java BUILD file depends on yet_another_package" >&2
    has_java_build=1
else
    echo "BUGGY: Java BUILD file does not depend on yet_another_package" >&2
    has_java_build=0
fi

# Check if enums.proto imports yet_another_package/embed.proto
if grep -q 'yet_another_package/embed.proto' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: enums.proto imports yet_another_package" >&2
    has_enum_import=1
else
    echo "BUGGY: enums.proto does not import yet_another_package" >&2
    has_enum_import=0
fi

# Check if enums.proto has RepeatedYetAnotherExternalEnumDefined message
if grep -q 'RepeatedYetAnotherExternalEnumDefined' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: enums.proto has RepeatedYetAnotherExternalEnumDefined" >&2
    has_enum_message=1
else
    echo "BUGGY: enums.proto does not have RepeatedYetAnotherExternalEnumDefined" >&2
    has_enum_message=0
fi

# Check if yet_another_package/BUILD exists
if [ -f tests/harness/cases/yet_another_package/BUILD ]; then
    echo "FIXED: yet_another_package/BUILD exists" >&2
    has_yap_build=1
else
    echo "BUGGY: yet_another_package/BUILD does not exist" >&2
    has_yap_build=0
fi

# Check if yet_another_package/embed.proto exists
if [ -f tests/harness/cases/yet_another_package/embed.proto ]; then
    echo "FIXED: yet_another_package/embed.proto exists" >&2
    has_yap_proto=1
else
    echo "BUGGY: yet_another_package/embed.proto does not exist" >&2
    has_yap_proto=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_gitignore -eq 1 ] && [ $has_makefile -eq 1 ] && \
   [ $has_pom -eq 1 ] && [ $has_java_build -eq 1 ] && \
   [ $has_enum_import -eq 1 ] && [ $has_enum_message -eq 1 ] && \
   [ $has_yap_build -eq 1 ] && [ $has_yap_proto -eq 1 ]; then
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
