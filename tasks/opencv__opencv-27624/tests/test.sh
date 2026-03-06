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

# Check 1: ClipLayer class declaration exists in header
if grep -q 'class CV_EXPORTS ClipLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp declares ClipLayer class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing ClipLayer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: ClipLayer is registered in init.cpp
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(Clip.*ClipLayer)' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers ClipLayer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing ClipLayer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: clip_layer.cpp implementation file exists
if [ -f modules/dnn/src/layers/clip_layer.cpp ]; then
    echo "PASS: clip_layer.cpp implementation file exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clip_layer.cpp implementation file missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: ClipLayerImpl class exists in clip_layer.cpp
if [ -f modules/dnn/src/layers/clip_layer.cpp ] && grep -q 'class ClipLayerImpl' modules/dnn/src/layers/clip_layer.cpp; then
    echo "PASS: clip_layer.cpp contains ClipLayerImpl class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clip_layer.cpp missing ClipLayerImpl class (buggy version)" >&2
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
