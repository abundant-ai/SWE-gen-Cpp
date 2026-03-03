#!/bin/bash
set -eo pipefail

cd /app/src

# Set test data path environment variable
export OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance.cpp" "modules/dnn/test/test_onnx_conformance.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
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
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles with the fix
if ! cmake --build build --target opencv_test_dnn -j4 2>&1; then
    echo "FAIL: Build failed with the fix"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run only RoiAlign tests that have test data available
# test_roialign_mode_max fails due to missing test data, so we skip it
if ! ./build/bin/opencv_test_dnn --gtest_filter="*roialign_aligned*" 2>&1; then
    echo "FAIL: RoiAlign tests failed"
    test_status=1
else
    echo "SUCCESS: RoiAlign tests passed"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
