#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# The fix adds back 3D convolution support to the DNN module source code
# We validate by checking source files for 3D support indicators

# Check 1: onnx_importer.cpp should have parse() function for handling 3D arrays (fixed version)
if grep -q "static DictValue parse(const ::google::protobuf::RepeatedField" modules/dnn/src/onnx/onnx_importer.cpp; then
    echo "PASS: onnx_importer.cpp has parse() function (fixed version with 3D support)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer.cpp missing parse() function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: onnx_importer.cpp should accept kernel_shape size 2 OR 3 (fixed version supports 3D)
if grep -q "attribute_proto.ints_size() == 2 || attribute_proto.ints_size() == 3" modules/dnn/src/onnx/onnx_importer.cpp; then
    echo "PASS: onnx_importer.cpp supports 3D kernel shapes (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer.cpp only supports 2D kernel shapes (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_importer.cpp should have DATA_LAYOUT_NDHWC enum value (fixed version supports 3D)
if grep -q "DATA_LAYOUT_NDHWC" modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp has DATA_LAYOUT_NDHWC (fixed version with 3D support)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp missing DATA_LAYOUT_NDHWC (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tf_importer.cpp should support MaxPool3D type (fixed version supports 3D)
if grep -q 'type == "MaxPool" || type == "MaxPool3D"' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp supports MaxPool3D (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp does not support MaxPool3D (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: tf_importer.cpp should support AvgPool3D type (fixed version supports 3D)
if grep -q 'type == "AvgPool" || type == "AvgPool3D"' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp supports AvgPool3D (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp does not support AvgPool3D (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: convolution_layer.cpp should support 3D kernels (kernel_size.size() == 3)
if grep -q "kernel_size.size() == 3" modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp supports 3D kernels (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp does not support 3D kernels (buggy version)" >&2
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
