#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"

checks_passed=0
checks_failed=0

# PR #12336: Manage lifetime of CNNNetwork from Model Optimizer
# For harbor testing:
# - HEAD (4062ef5fcbf0a0453104eb3b4b3027bb6cf25579): Fixed version with netOwner member variable
# - BASE (after bug.patch): Buggy version without netOwner member variable
# - FIXED (after oracle applies fix): Back to fixed version with netOwner

# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: op_inf_engine.hpp should have netOwner member variable with comment (fixed version)
if grep -q 'InferenceEngine::CNNNetwork netOwner;' modules/dnn/src/op_inf_engine.hpp && \
   grep -q '// In case of models from Model Optimizer we need to manage their lifetime.' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp has netOwner member variable with comment - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp should have netOwner member variable with comment - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: op_inf_engine.cpp should assign netOwner in constructor (fixed version)
if grep -q 'netOwner = net;' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp assigns netOwner in constructor - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should assign netOwner in constructor - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

echo "Checks passed: $checks_passed, Checks failed: $checks_failed"

if [ $checks_failed -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
