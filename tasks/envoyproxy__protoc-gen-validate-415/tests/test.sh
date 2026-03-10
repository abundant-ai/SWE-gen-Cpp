#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state with the fixed version)
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/embed.proto" "tests/harness/cases/other_package/embed.proto"

# PR #415 adds support for the `module` parameter in the Go generator
# The fix should:
# 1. Parse the `module` parameter from plugin parameters
# 2. Strip the module prefix from output paths when generating files
# 3. Work correctly with fully-qualified go_package options

echo "Testing module parameter support for Go code generation..." >&2

# Test 1: Verify that module parameter is defined in the code
echo "Checking if moduleParam constant is defined..." >&2
if grep -q 'moduleParam.*=.*"module"' module/validate.go; then
    echo "PASS: moduleParam constant is defined" >&2
    has_param=1
else
    echo "FAIL: moduleParam constant not found" >&2
    has_param=0
fi

# Test 2: Verify that module parameter is read from parameters
echo "Checking if module parameter is read from Parameters()..." >&2
if grep -q 'module.*:=.*m\.Parameters()\.Str(moduleParam)' module/validate.go || \
   grep -q 'module := m\.Parameters()\.Str(moduleParam)' module/validate.go; then
    echo "PASS: module parameter is read from Parameters()" >&2
    has_read=1
else
    echo "FAIL: module parameter not read from Parameters()" >&2
    has_read=0
fi

# Test 3: Verify that module is used to transform output path
echo "Checking if module is used to strip prefix from output path..." >&2
if grep -q 'strings.ReplaceAll.*out.*module' module/validate.go || \
   grep -q 'ReplaceAll.*out.*module' module/validate.go; then
    echo "PASS: module is used to transform output path" >&2
    has_transform=1
else
    echo "FAIL: module not used to transform output path" >&2
    has_transform=0
fi

# Test 4: Verify outPath variable is used instead of out.String()
echo "Checking if transformed outPath is used in AddGeneratorTemplateFile..." >&2
if grep -q 'AddGeneratorTemplateFile(outPath' module/validate.go; then
    echo "PASS: outPath variable is used" >&2
    has_outpath=1
else
    echo "FAIL: outPath not used in AddGeneratorTemplateFile" >&2
    has_outpath=0
fi

# Test 5: Verify the embed.proto has fully-qualified go_package
echo "Checking if embed.proto uses fully-qualified go_package..." >&2
if grep -q 'option go_package = "github.com/envoyproxy/protoc-gen-validate/tests/harness/cases/other_package/go;other_package"' tests/harness/cases/other_package/embed.proto; then
    echo "PASS: embed.proto has fully-qualified go_package" >&2
    has_qualified=1
else
    echo "FAIL: embed.proto doesn't have fully-qualified go_package" >&2
    has_qualified=0
fi

# Test 6: Verify Makefile uses module parameter for other_package
echo "Checking if Makefile uses module parameter for validation..." >&2
if grep -q 'module=.*PACKAGE.*tests/harness/cases/other_package/go.*lang=go' Makefile || \
   grep -q '--validate_out=.*module=.*other_package' Makefile; then
    echo "PASS: Makefile uses module parameter" >&2
    has_makefile=1
else
    echo "FAIL: Makefile doesn't use module parameter correctly" >&2
    has_makefile=0
fi

# Test 7: Verify strings import is present (needed for ReplaceAll)
echo "Checking if strings package is imported..." >&2
if grep -q '"strings"' module/validate.go; then
    echo "PASS: strings package is imported" >&2
    has_import=1
else
    echo "FAIL: strings package not imported" >&2
    has_import=0
fi

# All checks must pass
if [ $has_param -eq 1 ] && [ $has_read -eq 1 ] && [ $has_transform -eq 1 ] && \
   [ $has_outpath -eq 1 ] && [ $has_qualified -eq 1 ] && [ $has_makefile -eq 1 ] && \
   [ $has_import -eq 1 ]; then
    echo "PASS: All PR #415 module parameter support is present" >&2
    test_status=0
else
    echo "FAIL: Some PR #415 changes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
