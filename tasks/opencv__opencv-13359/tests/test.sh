#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13359: The PR adds ConstLayer class for TensorFlow constant inputs in Concat
# For harbor testing:
# - HEAD (c9e0c77d737ccad87261af0b084f99fc0fc901bb): ConstLayer is implemented (fixed version)
# - BASE (after bug.patch): ConstLayer is missing (buggy version)
# - FIXED (after fix.patch): ConstLayer is implemented again (back to HEAD)

# Check 1: all_layers.hpp should have ConstLayer class declaration
if grep -q 'class CV_EXPORTS ConstLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp has ConstLayer class declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing ConstLayer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: init.cpp should register ConstLayer
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(Const,          ConstLayer);' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers ConstLayer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing ConstLayer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: const_layer.cpp should exist with implementation
if [ -f modules/dnn/src/layers/const_layer.cpp ]; then
    echo "PASS: const_layer.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: const_layer.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: const_layer.cpp should have ConstLayerImpl class
if [ -f modules/dnn/src/layers/const_layer.cpp ] && grep -q 'class ConstLayerImpl CV_FINAL : public ConstLayer' modules/dnn/src/layers/const_layer.cpp; then
    echo "PASS: const_layer.cpp has ConstLayerImpl class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: const_layer.cpp missing ConstLayerImpl class (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: tf_importer.cpp should create Const layers for constant inputs
if grep -q 'lp.type = "Const";' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp creates Const layers (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp not creating Const layers (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: tf_importer.cpp should add constant layers before Concat
if grep -q 'int constInpId = dstNet.addLayer(lp.name, lp.type, lp);' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp adds constant layers (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp not adding constant layers (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_tf_importer.cpp should have keras_pad_concat test (removed in buggy version)
if grep -q 'runTensorFlowNet("keras_pad_concat")' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp has keras_pad_concat test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp missing keras_pad_concat test (buggy version)" >&2
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
