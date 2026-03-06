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

# Check 1: BitShiftLayer class should be declared in all_layers.hpp (fixed version)
if grep -q 'class CV_EXPORTS BitShiftLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp declares BitShiftLayer class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing BitShiftLayer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: BitShift layer should be registered in init.cpp (fixed version)
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(BitShift,' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers BitShift layer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing BitShift layer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: bitshift_layer.cpp implementation file should exist (fixed version)
if [ -f "modules/dnn/src/layers/bitshift_layer.cpp" ]; then
    echo "PASS: bitshift_layer.cpp implementation exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bitshift_layer.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: BitShift parser should be declared in onnx_importer2.cpp (fixed version)
if grep -q 'void parseBitShift' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp declares parseBitShift method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing parseBitShift declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: BitShift parser should be registered in dispatch map (fixed version)
if grep -q 'dispatch\["BitShift"\]' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp registers BitShift in dispatch map (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing BitShift dispatch registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: UINT16/UINT32/UINT64 data types should be supported in graph simplifier (fixed version)
if grep -q 'TensorProto_DataType_UINT16' modules/dnn/src/onnx/onnx_graph_simplifier.cpp; then
    echo "PASS: onnx_graph_simplifier.cpp supports UINT16 data type (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_graph_simplifier.cpp missing UINT16 data type support (buggy version)" >&2
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
