#!/bin/bash
set -eo pipefail

cd /app/src

# Set test data path environment variable
export OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.impl.hpp" "modules/dnn/test/test_common.impl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"

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

# Run tests related to Reduce operations and Shape operations
# These tests cover the shape inference bug that was fixed
# Using --gtest_filter to run only tests that have necessary ONNX test data files
if ! ./build/bin/opencv_test_dnn \
    --gtest_filter="*ONNX_layers.Shape/*:*ONNX_layers.ReduceMean/*:*ONNX_layers.ReduceSum/*:*ONNX_layers.ReduceMax/*:*ONNX_layers.ReduceMax_axis_0/*:*ONNX_layers.ReduceMax_axis_1/*:*ONNX_layers.ReduceMean3D/*:*ONNX_layers.ReduceL2/*" 2>&1; then
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
