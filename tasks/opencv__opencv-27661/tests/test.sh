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

# Check 1: IsNaNLayer class declared in all_layers.hpp
if grep -q 'class CV_EXPORTS IsNaNLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp declares IsNaNLayer class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing IsNaNLayer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: IsNaN layer registered in init.cpp
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(IsNaN,' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers IsNaN layer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing IsNaN layer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: is_nan_layer.cpp implementation file exists
if [ -f "modules/dnn/src/layers/is_nan_layer.cpp" ]; then
    echo "PASS: is_nan_layer.cpp implementation exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: is_nan_layer.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: parseIsNaN method declared in onnx_importer2.cpp
if grep -q 'void parseIsNaN' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp declares parseIsNaN method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing parseIsNaN declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: IsNaN registered in dispatch map
if grep -q 'dispatch\["IsNaN"\]' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp registers IsNaN in dispatch map (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing IsNaN dispatch registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_isnan in OpenCV classic denylist
if grep -q '"test_isnan"' modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp; then
    echo "PASS: test_isnan in OpenCV classic denylist (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_isnan missing from OpenCV classic denylist (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_isnan NOT in parser denylist
if ! grep -q '"test_isnan"' modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp; then
    echo "PASS: test_isnan removed from parser denylist (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_isnan still in parser denylist (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_isnan has SKIP in openvino test file
if grep -A1 'CASE(test_isnan)' modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp | grep -q 'SKIP;'; then
    echo "PASS: test_isnan has SKIP in openvino test file (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_isnan missing SKIP in openvino test file (buggy version)" >&2
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
