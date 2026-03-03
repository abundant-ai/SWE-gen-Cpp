#!/bin/bash
set -eo pipefail

cd /app/src

# Set test data path environment variable
export OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

# Reconfigure CMake to pick up the updated test files
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_dnn=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -DWITH_PROTOBUF=ON \
    -DBUILD_PROTOBUF=ON \
    -DOPENCV_DNN_OPENCL=OFF \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles with the fix
if ! cmake --build build --target opencv_test_dnn -j2 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run ONNX conformance tests that are now enabled by BatchNorm2Layer support
# The fix removes these tests from the parser denylist, allowing them to be parsed and run
# Specifically testing: test_batchnorm_epsilon and test_batchnorm_example
if ! ./build/bin/opencv_test_dnn \
    --gtest_filter="*ONNX_conformance*test_batchnorm_epsilon*:*ONNX_conformance*test_batchnorm_example*" 2>&1; then
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
