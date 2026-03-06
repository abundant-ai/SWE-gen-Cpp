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

# Check 1: topk2_layer.cpp should exist (fixed version restores it)
if [ -f "modules/dnn/src/layers/topk2_layer.cpp" ]; then
    echo "PASS: topk2_layer.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: topk2_layer.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: TopK2Layer should be declared in all_layers.hpp (fixed version)
if grep -q 'class CV_EXPORTS TopK2Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp has TopK2Layer declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing TopK2Layer declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: TopK2Layer should be registered in init.cpp (fixed version)
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(TopK2,' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp has TopK2Layer registration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing TopK2Layer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp should have test_top_k (fixed version adds these)
if grep -q '"test_top_k"' modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp; then
    echo "PASS: test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp has test_top_k entry (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp missing test_top_k (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_onnx_conformance_layer_filter__openvino.inl.hpp should have SKIP for test_top_k (fixed version restores SKIP)
if grep -A1 'CASE(test_top_k)' modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp | grep -q 'SKIP;'; then
    echo "PASS: test_onnx_conformance_layer_filter__openvino.inl.hpp has SKIP for test_top_k (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_conformance_layer_filter__openvino.inl.hpp missing SKIP for test_top_k (buggy version)" >&2
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
