#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"

checks_passed=0
checks_failed=0

# PR #12590: Fix Intel Inference Engine backend device/plugin initialization
# For harbor testing:
# - HEAD (861415133e555df2158423726eed9290bbdfe1b9): Fixed version with proper MYRIAD device reset
# - BASE (after bug.patch): Buggy version without MYRIAD device reset
# - FIXED (after oracle applies fix): Back to fixed version with proper MYRIAD device reset

# Check 1: sharedPlugins SHOULD be declared at file scope (fixed version has it)
if grep -q '^static std::map<InferenceEngine::TargetDevice, InferenceEngine::InferenceEnginePluginPtr> sharedPlugins;' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: sharedPlugins declared at file scope - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: sharedPlugins not at file scope - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: sharedPlugins SHOULD NOT be declared inside initPlugin (buggy version has it there)
if grep -A 5 'void InfEngineBackendNet::initPlugin' modules/dnn/src/op_inf_engine.cpp | grep -q 'static std::map<InferenceEngine::TargetDevice, InferenceEngine::InferenceEnginePluginPtr> sharedPlugins;'; then
    echo "FAIL: sharedPlugins declared inside initPlugin - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: sharedPlugins not inside initPlugin - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: resetMyriadDevice function SHOULD exist (fixed version has it)
if grep -q 'void resetMyriadDevice()' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: resetMyriadDevice function exists - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resetMyriadDevice function missing - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: resetMyriadDevice SHOULD erase eMYRIAD from sharedPlugins (fixed version has it)
if grep -q 'sharedPlugins.erase(InferenceEngine::TargetDevice::eMYRIAD)' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: resetMyriadDevice erases MYRIAD device - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resetMyriadDevice doesn't erase MYRIAD - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Test file SHOULD call resetMyriadDevice (fixed version has it)
if grep -q 'resetMyriadDevice()' modules/dnn/test/test_ie_models.cpp; then
    echo "PASS: Test calls resetMyriadDevice - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test doesn't call resetMyriadDevice - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test file SHOULD have MYRIAD target enabled (fixed version has it)
if grep -q 'if (checkMyriadTarget())' modules/dnn/test/test_ie_models.cpp && \
   ! grep -q '//if (checkMyriadTarget())' modules/dnn/test/test_ie_models.cpp; then
    echo "PASS: MYRIAD target enabled in tests - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MYRIAD target disabled in tests - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Test file SHOULD skip certain models on MYRIAD (fixed version has these checks)
if grep -q 'if (target == DNN_TARGET_MYRIAD && (modelName == "landmarks-regression-retail-0001"' modules/dnn/test/test_ie_models.cpp; then
    echo "PASS: Test has MYRIAD model skip checks - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test missing MYRIAD model skip checks - buggy version" >&2
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
