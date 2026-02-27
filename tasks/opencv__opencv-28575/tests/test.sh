#!/bin/bash

cd /app/src

# Set test data path
export OPENCV_TEST_DATA_PATH=/app/opencv_extra/testdata

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.impl.hpp" "modules/dnn/test/test_common.impl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"

# Rebuild test executable with updated test files
cd /app/build
ninja opencv_test_dnn

# Run only the ONNX importer tests (which use test_common.impl.hpp)
# Using gtest filter to run only the Test_ONNX_* tests
./bin/opencv_test_dnn --gtest_filter="Test_ONNX_*"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
