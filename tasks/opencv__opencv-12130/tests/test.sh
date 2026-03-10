#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12130: Fix layer fusion and BatchNormLayer activation support
# The fix changes BatchNormLayer to inherit from ActivationLayer and fixes fusion logic

# Check 1: BatchNormLayer should inherit from ActivationLayer in all_layers.hpp
if grep -q "class CV_EXPORTS BatchNormLayer : public ActivationLayer" modules/dnn/include/opencv2/dnn/all_layers.hpp 2>/dev/null; then
    echo "PASS: BatchNormLayer inherits from ActivationLayer in all_layers.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: BatchNormLayer should inherit from ActivationLayer in all_layers.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: The "else if (node.empty()) continue;" guard should exist in dnn.cpp
if grep -A 2 "node = layer->initInfEngine" modules/dnn/src/dnn.cpp 2>/dev/null | grep -q "else if (node.empty())"; then
    echo "PASS: Empty node guard exists in dnn.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Empty node guard should exist in dnn.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: The while loop for fusion should exist in dnn.cpp
if grep -q "while (nextData)" modules/dnn/src/dnn.cpp 2>/dev/null; then
    echo "PASS: while (nextData) loop exists in dnn.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: while (nextData) loop should exist in dnn.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: BatchNormLayer should have forwardSlice method in batch_norm_layer.cpp
if grep -q "void forwardSlice(const float\* srcptr, float\* dstptr, int len, size_t planeSize, int cn0, int cn1)" modules/dnn/src/layers/batch_norm_layer.cpp 2>/dev/null; then
    echo "PASS: forwardSlice method exists in batch_norm_layer.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: forwardSlice method should exist in batch_norm_layer.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: ConvolutionLayer setActivation should check for existing activation
if grep -A 2 "bool setActivation(const Ptr<ActivationLayer>& layer)" modules/dnn/src/layers/convolution_layer.cpp 2>/dev/null | grep -q "if (!activ.empty() && !layer.empty())"; then
    echo "PASS: ConvolutionLayer setActivation checks for existing activation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ConvolutionLayer setActivation should check for existing activation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: MVN layer should have op_inf_engine.hpp include
if grep -q '#include "../op_inf_engine.hpp"' modules/dnn/src/layers/mvn_layer.cpp 2>/dev/null; then
    echo "PASS: MVN layer includes op_inf_engine.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MVN layer should include op_inf_engine.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: MVN layer should have initInfEngine method
if grep -q "virtual Ptr<BackendNode> initInfEngine" modules/dnn/src/layers/mvn_layer.cpp 2>/dev/null; then
    echo "PASS: MVN layer has initInfEngine method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MVN layer should have initInfEngine method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Test case mvn_batch_norm should be in same TEST_P as batch_norm
# (NOT split into a separate test in the fixed version)
if grep -B 15 "runTensorFlowNet(\"mvn_batch_norm\")" modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q "TEST_P(Test_TensorFlow_layers, batch_norm)"; then
    echo "PASS: mvn_batch_norm is in batch_norm test case"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_batch_norm should be in batch_norm test case (not separate)" >&2
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
