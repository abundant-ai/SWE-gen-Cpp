#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__cuda_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__cuda_denylist.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__cuda_fp16_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__cuda_fp16_denylist.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__vulkan_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__vulkan_denylist.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

# Reconfigure cmake to pick up the new test files, then rebuild
cd build
cmake -GNinja \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_DOCS=OFF \
    ..
ninja -j2 opencv_test_dnn

test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
