#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

# Check if bitwise operations are supported in the source code
# In BASE state (buggy), BITWISE_AND/OR/XOR enums are missing from nary_eltwise_layers.cpp
# In HEAD state (fixed), these enums exist
if grep -q "BITWISE_AND" modules/dnn/src/layers/nary_eltwise_layers.cpp && \
   grep -q "BITWISE_OR" modules/dnn/src/layers/nary_eltwise_layers.cpp && \
   grep -q "BITWISE_XOR" modules/dnn/src/layers/nary_eltwise_layers.cpp; then
    echo "PASS: Bitwise operations found in source code (fixed version)"
    test_status=0
else
    echo "FAIL: Bitwise operations missing from source code (buggy version)" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
