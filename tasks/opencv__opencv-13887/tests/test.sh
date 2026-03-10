#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"

checks_passed=0
checks_failed=0

# PR #13887 fixes LRN layer to properly enforce Inference Engine backend limitations
# HEAD (4cbd09c41c2051b2b21144b770a566184a553503): Proper backend limitation checks
# BASE (after bug.patch): Missing backend limitation enforcement
# FIXED (after fix.patch): Proper backend limitation checks (matches HEAD)

# Check 1: supportBackend should check bias and Myriad constraints for Inference Engine (fixed version)
if grep -A 2 'if (backendId == DNN_BACKEND_INFERENCE_ENGINE)' modules/dnn/src/layers/lrn_layer.cpp | grep -q 'return (bias == 1) && (preferableTarget != DNN_TARGET_MYRIAD || type == SPATIAL_NRM)'; then
    echo "PASS: supportBackend checks bias and Myriad constraints (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: supportBackend missing proper constraint checks (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: initInfEngine should declare alphaSize variable (fixed version)
if grep -q 'float alphaSize = alpha' modules/dnn/src/layers/lrn_layer.cpp; then
    echo "PASS: initInfEngine declares alphaSize variable (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: initInfEngine missing alphaSize declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: initInfEngine should calculate alphaSize based on normBySize (fixed version)
if grep -q 'if (!normBySize)' modules/dnn/src/layers/lrn_layer.cpp && \
   grep -q 'alphaSize \*= (type == SPATIAL_NRM ? size\*size : size)' modules/dnn/src/layers/lrn_layer.cpp; then
    echo "PASS: initInfEngine calculates alphaSize based on normBySize (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: initInfEngine missing alphaSize calculation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: setAlpha should use alphaSize instead of alpha (fixed version)
if grep -q 'ieLayer.setAlpha(alphaSize)' modules/dnn/src/layers/lrn_layer.cpp; then
    echo "PASS: setAlpha uses alphaSize (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setAlpha not using alphaSize (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: ieLayer->_alpha should use alphaSize instead of alpha (fixed version)
if grep -q 'ieLayer->_alpha = alphaSize' modules/dnn/src/layers/lrn_layer.cpp; then
    echo "PASS: ieLayer->_alpha uses alphaSize (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ieLayer->_alpha not using alphaSize (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: netBuilder.connect should cast portIds[i] to size_t (fixed version)
if grep -q 'netBuilder.connect((size_t)blobsIds\[i\], {(size_t)id, (size_t)portIds\[i\]})' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: netBuilder.connect properly casts portIds[i] to size_t (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: netBuilder.connect missing portIds[i] size_t cast (buggy version)" >&2
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
