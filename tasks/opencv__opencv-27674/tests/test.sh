#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

checks_passed=0
checks_failed=0

# Check 1: NonMaxSuppressionLayer class should be declared in all_layers.hpp (fixed version)
if grep -q 'class CV_EXPORTS NonMaxSuppressionLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp declares NonMaxSuppressionLayer class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing NonMaxSuppressionLayer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: NonMaxSuppression layer should be registered in init.cpp (fixed version)
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(NonMaxSuppression,' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers NonMaxSuppression layer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing NonMaxSuppression layer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: nonmaxsuppression_layer.cpp implementation file should exist (fixed version)
if [ -f "modules/dnn/src/layers/nonmaxsuppression_layer.cpp" ]; then
    echo "PASS: nonmaxsuppression_layer.cpp implementation exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: nonmaxsuppression_layer.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: NonMaxSuppression parser should be declared in onnx_importer2.cpp (fixed version)
if grep -q 'void parseNonMaxSuprression' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp declares parseNonMaxSuprression method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing parseNonMaxSuprression declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: NonMaxSuppression parser should be registered in dispatch map (fixed version)
if grep -q 'dispatch\["NonMaxSuprression"\]' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp registers NonMaxSuppression in dispatch map (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing NonMaxSuppression dispatch registration (buggy version)" >&2
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
