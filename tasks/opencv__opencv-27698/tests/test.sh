#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__cuda_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__cuda_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__cuda_fp16_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__cuda_fp16_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

checks_passed=0
checks_failed=0

# Check 1: Cast2Layer class should be declared in all_layers.hpp (fixed version)
if grep -q 'class CV_EXPORTS Cast2Layer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp declares Cast2Layer class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing Cast2Layer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Cast2 layer should be registered in init.cpp (fixed version)
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(Cast2,' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers Cast2 layer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing Cast2 layer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: cast2_layer.cpp implementation file should exist (fixed version)
if [ -f "modules/dnn/src/layers/cast2_layer.cpp" ]; then
    echo "PASS: cast2_layer.cpp implementation exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cast2_layer.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: CV_16F type conversion should be supported in ie_ngraph.cpp (fixed version)
if grep -q 'case CV_16F:' modules/dnn/src/ie_ngraph.cpp && grep -q 'return ov::element::f16;' modules/dnn/src/ie_ngraph.cpp; then
    echo "PASS: ie_ngraph.cpp supports CV_16F type conversion (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ie_ngraph.cpp missing CV_16F type conversion (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: CV_64F type conversion should be supported in ie_ngraph.cpp (fixed version)
if grep -q 'case CV_64F:' modules/dnn/src/ie_ngraph.cpp && grep -q 'return ov::element::f64;' modules/dnn/src/ie_ngraph.cpp; then
    echo "PASS: ie_ngraph.cpp supports CV_64F type conversion (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ie_ngraph.cpp missing CV_64F type conversion (buggy version)" >&2
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
