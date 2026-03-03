#!/bin/bash
set -eo pipefail

cd /app/src

# Set test data path environment variable
export OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

# Reconfigure CMake to pick up the updated test files
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_dnn=ON \
    -DWITH_PROTOBUF=ON \
    -DBUILD_PROTOBUF=ON \
    -DOPENCV_DNN_OPENCL=OFF \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles with the fix
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run tests related to GRU operator support in ONNX conformance
# The fix adds GRU parsing support to the new ONNX importer
# The modified test files filter which ONNX conformance tests should run
# Using --gtest_filter to run ONNX conformance tests that include GRU operations
if ! ./build/bin/opencv_test_dnn \
    --gtest_filter="*ONNX_conformance*test_gru*" 2>&1; then
    echo "FAIL: Tests failed"
    test_status=1
else
    echo "SUCCESS: All tests passed"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
