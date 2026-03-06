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

# Check 1: Resize2Layer class declaration exists in all_layers.hpp (fixed version)
if grep -q 'class CV_EXPORTS Resize2Layer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp contains Resize2Layer class declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing Resize2Layer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Resize2Layer registration in init.cpp (fixed version)
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(Resize2,.*Resize2Layer)' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers Resize2Layer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing Resize2Layer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: resize2_layer.cpp implementation file exists (fixed version)
if [ -f modules/dnn/src/layers/resize2_layer.cpp ]; then
    echo "PASS: resize2_layer.cpp implementation file exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize2_layer.cpp implementation file missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: CoordTransMode enum in resize2_layer.cpp (fixed version)
if [ -f modules/dnn/src/layers/resize2_layer.cpp ] && grep -q 'enum class CoordTransMode' modules/dnn/src/layers/resize2_layer.cpp; then
    echo "PASS: resize2_layer.cpp contains CoordTransMode enum (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize2_layer.cpp missing CoordTransMode enum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: NearestMode enum in resize2_layer.cpp (fixed version)
if [ -f modules/dnn/src/layers/resize2_layer.cpp ] && grep -q 'enum class NearestMode' modules/dnn/src/layers/resize2_layer.cpp; then
    echo "PASS: resize2_layer.cpp contains NearestMode enum (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize2_layer.cpp missing NearestMode enum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: parseCoordTransMode function in resize2_layer.cpp (fixed version)
if [ -f modules/dnn/src/layers/resize2_layer.cpp ] && grep -q 'parseCoordTransMode' modules/dnn/src/layers/resize2_layer.cpp; then
    echo "PASS: resize2_layer.cpp contains parseCoordTransMode function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize2_layer.cpp missing parseCoordTransMode function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: parseNearestMode function in resize2_layer.cpp (fixed version)
if [ -f modules/dnn/src/layers/resize2_layer.cpp ] && grep -q 'parseNearestMode' modules/dnn/src/layers/resize2_layer.cpp; then
    echo "PASS: resize2_layer.cpp contains parseNearestMode function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize2_layer.cpp missing parseNearestMode function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: ONNX Resize operator documentation in resize2_layer.cpp (fixed version)
if [ -f modules/dnn/src/layers/resize2_layer.cpp ] && grep -q 'ONNX Resize operator' modules/dnn/src/layers/resize2_layer.cpp; then
    echo "PASS: resize2_layer.cpp documents ONNX Resize operator implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize2_layer.cpp missing ONNX Resize documentation (buggy version)" >&2
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
