#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13397: The PR improves handling of TensorFlow's "Sub" operation in DNN module
# For harbor testing:
# - HEAD (ea64e860deaab633d2f992066b1da26e31811432): Has the fixes (current git state)
# - BASE (after bug.patch): Fixes removed (simulates the buggy state)
# - FIXED (after fix.patch): Fixes restored (back to HEAD/current git state)

# Check 1: tf_importer.cpp should handle "Sub" along with "BiasAdd" and "Add"
if grep -q 'else if (type == "BiasAdd" || type == "Add" || type == "Sub")' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp handles Sub along with BiasAdd and Add (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp missing Sub in BiasAdd/Add handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tf_importer.cpp should have Sub negation logic when type is Sub
if grep -q 'if (type == "Sub")' modules/dnn/src/tensorflow/tf_importer.cpp | head -1 && \
   grep -q 'values \*= -1.0f;' modules/dnn/src/tensorflow/tf_importer.cpp | head -2; then
    echo "PASS: tf_importer.cpp has Sub negation logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp missing Sub negation logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_importer.cpp should have Sub coefficient handling for Eltwise layer
if grep -A 3 'if (type == "Sub")' modules/dnn/src/tensorflow/tf_importer.cpp | grep -q 'static float subCoeffs\[\] = {1.f, -1.f};' && \
   grep -A 4 'if (type == "Sub")' modules/dnn/src/tensorflow/tf_importer.cpp | grep -q 'layerParams.set("coeff", DictValue::arrayReal<float\*>(subCoeffs, 2));'; then
    echo "PASS: tf_importer.cpp has Sub coefficient handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp missing Sub coefficient handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tf_importer.cpp should NOT have separate "else if (type == Sub)" block
if grep -q 'else if (type == "Sub")' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "FAIL: tf_importer.cpp has separate Sub handling block (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: tf_importer.cpp does not have separate Sub block (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: test_tf_importer.cpp should have renamed test to eltwise_add_mul
if grep -q 'TEST_P(Test_TensorFlow_layers, eltwise_add_mul)' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp has eltwise_add_mul test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp missing eltwise_add_mul test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_tf_importer.cpp should NOT call runTensorFlowNet("eltwise_sub")
if grep -q 'runTensorFlowNet("eltwise_sub")' modules/dnn/test/test_tf_importer.cpp; then
    echo "FAIL: test_tf_importer.cpp still has eltwise_sub call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: test_tf_importer.cpp does not have eltwise_sub call (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 7: eltwise_layer.cpp should check for (preferableTarget != DNN_TARGET_MYRIAD || coeffs.empty())
if grep -F '(preferableTarget != DNN_TARGET_MYRIAD || coeffs.empty())' modules/dnn/src/layers/eltwise_layer.cpp; then
    echo "PASS: eltwise_layer.cpp has correct preferableTarget check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: eltwise_layer.cpp missing preferableTarget check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: eltwise_layer.cpp should set ieLayer->coeff
if grep -q 'ieLayer->coeff = coeffs;' modules/dnn/src/layers/eltwise_layer.cpp; then
    echo "PASS: eltwise_layer.cpp sets ieLayer->coeff (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: eltwise_layer.cpp missing ieLayer->coeff assignment (buggy version)" >&2
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
