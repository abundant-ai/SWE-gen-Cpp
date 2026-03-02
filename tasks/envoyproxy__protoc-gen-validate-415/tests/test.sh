#!/bin/bash

cd /app/src

export CI=true

# Verify that the module parameter support is correctly implemented
# For NOP: Code is in buggy state (no module support), tests fail (reward=0)
# For Oracle: solve.sh applies fix.patch, module support is added, tests pass (reward=1)

echo "Checking if module parameter is supported..."

# Check if module/validate.go has the moduleParam constant
if grep -q 'moduleParam.*=.*"module"' module/validate.go; then
    echo "✓ moduleParam constant found"
    module_param_const=0
else
    echo "✗ moduleParam constant not found"
    module_param_const=1
fi

# Check if module parameter is being read
if grep -q 'module.*:=.*m\.Parameters()\.Str(moduleParam)' module/validate.go; then
    echo "✓ module parameter is being read"
    module_read=0
else
    echo "✗ module parameter is not being read"
    module_read=1
fi

# Check if strings package is imported (needed for module path manipulation)
if grep -q '"strings"' module/validate.go; then
    echo "✓ strings package imported"
    strings_import=0
else
    echo "✗ strings package not imported"
    strings_import=1
fi

# Check if module path replacement is implemented
if grep -q 'strings.ReplaceAll.*module' module/validate.go; then
    echo "✓ module path replacement implemented"
    module_replace=0
else
    echo "✗ module path replacement not implemented"
    module_replace=1
fi

# Check if README.md documents the module parameter
if grep -q 'module=example.com/foo' README.md; then
    echo "✓ README.md documents module parameter"
    readme_docs=0
else
    echo "✗ README.md doesn't document module parameter"
    readme_docs=1
fi

if [ $module_param_const -eq 0 ] && [ $module_read -eq 0 ] && [ $strings_import -eq 0 ] && [ $module_replace -eq 0 ] && [ $readme_docs -eq 0 ]; then
    echo "All tests passed!"
    test_status=0
else
    echo "Some tests failed!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
