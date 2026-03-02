#!/bin/bash
set -x
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

# Rebuild the plugin to pick up any template changes
make build

# Regenerate test cases from proto files
make testcases

# The fix should properly handle multiple external enum imports with unique aliases
# With the bug, the generated code has issues:
# 1) Missing imports for external enums used in repeated field validation
# 2) Duplicate import aliases when multiple external packages share the same derived name
# 3) Invalid enum reference syntax (mixing proto path with Go identifier)
# With the fix, the generated validation file should:
# - Import all required external enum packages
# - Use unique import aliases (e.g., _go and _go1 if there's a collision)
# - Use valid Go syntax for enum references (alias.EnumType)

# Check if the generated validation file has the correct import for yet_another_package
# With the bug, externalEnums() doesn't detect enums in repeated field validation rules,
# so the import will be missing even though the validation code references it
# With the fix, the import should be present with a unique alias (e.g., _go1 if _go is already used)

# Check for import of yet_another_package in the imports section
if grep -A 20 "^import (" tests/harness/cases/go/enums.pb.validate.go 2>/dev/null | grep -q "yet_another_package/go"; then
    import_found=1
else
    import_found=0
fi

# Test passes if yet_another_package import is found (means fix is applied)
if [ $import_found -eq 1 ]; then
    test_status=0
else
    echo "Test failed - yet_another_package import not found in generated validation file"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
