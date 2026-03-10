#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# Check 1: dnn.hpp should have ONNX documentation (fixed version)
if grep -q '\.onnx.*ONNX.*https://onnx.ai' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has ONNX documentation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp missing ONNX documentation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tf_importer.cpp should have StridedSlice implementation (fixed version)
if grep -q 'else if (type == "StridedSlice")' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp has StridedSlice implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp missing StridedSlice implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_onnx_importer.cpp should have correct log_softmax test call (fixed version)
if grep -q 'testONNXModels("log_softmax", npy, 0, 0, false, false);' modules/dnn/test/test_onnx_importer.cpp; then
    echo "PASS: test_onnx_importer.cpp has correct log_softmax test call (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp has simplified log_softmax test call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_tf_importer.cpp should have strided_slice test (fixed version)
if grep -q 'runTensorFlowNet("strided_slice");' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp has strided_slice test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp missing strided_slice test (buggy version)" >&2
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
