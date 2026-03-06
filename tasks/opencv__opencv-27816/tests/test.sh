#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

# Check if Reduce2Layer class exists in the source code
# In BASE state (buggy), the Reduce2Layer class is removed from all_layers.hpp
# In HEAD state (fixed), the class exists
if grep -q "class CV_EXPORTS Reduce2Layer" modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: Reduce2Layer class found in source code (fixed version)"
    test_status=0
else
    echo "FAIL: Reduce2Layer class missing from source code (buggy version)" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
