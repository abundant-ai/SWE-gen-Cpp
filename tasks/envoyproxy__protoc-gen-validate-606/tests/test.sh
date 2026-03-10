#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/python"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# The test verifies that validate_all functionality is properly implemented
#
# In the buggy state (BASE with bug.patch applied):
#   - validate_all function and its implementation are removed from validator.py
#   - astunparse dependency is removed from requirements
#   - harness.py doesn't test validate_all (only tests validate)
#
# In the fixed state (BASE + HEAD test files):
#   - validate_all function is added to validator.py with AST transformation logic
#   - astunparse dependency is added to requirements
#   - harness.py tests both validate and validate_all with consistency checks

echo "Testing if validate_all functionality is properly implemented..." >&2

# Check if validator.py has the validate_all function
if grep -q 'def validate_all' python/protoc_gen_validate/validator.py 2>/dev/null; then
    echo "FIXED: validate_all function exists in validator.py" >&2
    has_validate_all=1
else
    echo "BUGGY: validate_all function is missing from validator.py" >&2
    has_validate_all=0
fi

# Check if validator.py has the _validate_all_inner function
if grep -q 'def _validate_all_inner' python/protoc_gen_validate/validator.py 2>/dev/null; then
    echo "FIXED: _validate_all_inner function exists in validator.py" >&2
    has_validate_all_inner=1
else
    echo "BUGGY: _validate_all_inner function is missing from validator.py" >&2
    has_validate_all_inner=0
fi

# Check if validator.py imports ast module (needed for AST transformations)
if grep -q '^import ast' python/protoc_gen_validate/validator.py 2>/dev/null; then
    echo "FIXED: validator.py imports ast module" >&2
    has_ast_import=1
else
    echo "BUGGY: validator.py does not import ast module" >&2
    has_ast_import=0
fi

# Check if validator.py has AST transformer classes
if grep -q 'class ChangeFuncName' python/protoc_gen_validate/validator.py 2>/dev/null; then
    echo "FIXED: validator.py has AST transformer classes" >&2
    has_ast_transformers=1
else
    echo "BUGGY: validator.py is missing AST transformer classes" >&2
    has_ast_transformers=0
fi

# Check if setup.cfg includes astunparse dependency
if grep -q 'astunparse' python/setup.cfg 2>/dev/null; then
    echo "FIXED: setup.cfg includes astunparse dependency" >&2
    has_astunparse_dep=1
else
    echo "BUGGY: setup.cfg is missing astunparse dependency" >&2
    has_astunparse_dep=0
fi

# Check if harness.py tests validate_all
if grep -q 'validate_all(test_msg)' tests/harness/python/harness.py 2>/dev/null; then
    echo "FIXED: harness.py tests validate_all" >&2
    has_harness_test=1
else
    echo "BUGGY: harness.py does not test validate_all" >&2
    has_harness_test=0
fi

# Check if harness.py has consistency checks between validate and validate_all
if grep -q 'result.Valid != result_all.Valid' tests/harness/python/harness.py 2>/dev/null; then
    echo "FIXED: harness.py has consistency checks between validate and validate_all" >&2
    has_consistency_check=1
else
    echo "BUGGY: harness.py is missing consistency checks" >&2
    has_consistency_check=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_validate_all -eq 1 ] && [ $has_validate_all_inner -eq 1 ] && [ $has_ast_import -eq 1 ] && \
   [ $has_ast_transformers -eq 1 ] && [ $has_astunparse_dep -eq 1 ] && [ $has_harness_test -eq 1 ] && \
   [ $has_consistency_check -eq 1 ]; then
    echo "PASS: All validate_all functionality is present" >&2
    test_status=0
else
    echo "FAIL: Some validate_all functionality is missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
