#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11728: Enable SSD TensorFlow models (MobileNet-SSD, Inception-SSD) with IE backend on OpenCL

# Check 1: test_backends.cpp - MobileNet_SSD_v1_TensorFlow test should exist
if grep -q 'TEST_P(DNNTestNetwork, MobileNet_SSD_v1_TensorFlow)' modules/dnn/test/test_backends.cpp; then
    echo "PASS: MobileNet_SSD_v1_TensorFlow test exists in test_backends.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD_v1_TensorFlow test should exist in test_backends.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: test_backends.cpp - MobileNet_SSD_v2_TensorFlow test should exist
if grep -q 'TEST_P(DNNTestNetwork, MobileNet_SSD_v2_TensorFlow)' modules/dnn/test/test_backends.cpp; then
    echo "PASS: MobileNet_SSD_v2_TensorFlow test exists in test_backends.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD_v2_TensorFlow test should exist in test_backends.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_backends.cpp - MobileNet_SSD_v1_TensorFlow should NOT skip INFERENCE_ENGINE
if ! grep -A 3 'TEST_P(DNNTestNetwork, MobileNet_SSD_v1_TensorFlow)' modules/dnn/test/test_backends.cpp | grep -q 'backend == DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: MobileNet_SSD_v1_TensorFlow test does not skip INFERENCE_ENGINE backend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD_v1_TensorFlow test should not skip INFERENCE_ENGINE backend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_backends.cpp - Inception_v2_SSD should NOT skip IE + OPENCL
if ! grep -A 3 'TEST_P(DNNTestNetwork, Inception_v2_SSD_TensorFlow)' modules/dnn/test/test_backends.cpp | grep -q 'backend == DNN_BACKEND_INFERENCE_ENGINE && target == DNN_TARGET_OPENCL'; then
    echo "PASS: Inception_v2_SSD_TensorFlow test does not skip INFERENCE_ENGINE + OPENCL"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Inception_v2_SSD_TensorFlow test should not skip INFERENCE_ENGINE + OPENCL" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_backends.cpp - processNet should have detectionConfThresh parameter
if grep -A 5 'void processNet' modules/dnn/test/test_backends.cpp | grep -q 'detectionConfThresh'; then
    echo "PASS: processNet method has detectionConfThresh parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: processNet method should have detectionConfThresh parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_backends.cpp - check method should have detectionConfThresh parameter
if grep -A 2 'void check' modules/dnn/test/test_backends.cpp | grep -q 'detectionConfThresh'; then
    echo "PASS: check method has detectionConfThresh parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: check method should have detectionConfThresh parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_layers.cpp - Layer_Test_DWconv_Prelu should set OPENCV backend
if grep -A 100 'TEST_P(Layer_Test_DWconv_Prelu, Accuracy)' modules/dnn/test/test_layers.cpp | grep -q 'net.setPreferableBackend(DNN_BACKEND_OPENCV)'; then
    echo "PASS: Layer_Test_DWconv_Prelu test sets OPENCV backend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Layer_Test_DWconv_Prelu test should set OPENCV backend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: tf_text_graph_ssd.py - addConcatNode should have axisNodeName parameter
if grep -A 5 'def addConcatNode' samples/dnn/tf_text_graph_ssd.py | grep -q 'axisNodeName'; then
    echo "PASS: addConcatNode function has axisNodeName parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: addConcatNode function should have axisNodeName parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: tf_text_graph_ssd.py - should have addConstNode function
if grep -q 'def addConstNode' samples/dnn/tf_text_graph_ssd.py; then
    echo "PASS: addConstNode function is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: addConstNode function should be present" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: tf_text_graph_ssd.py - should add PriorBox/concat/axis constant
if grep -q "addConstNode('PriorBox/concat/axis'" samples/dnn/tf_text_graph_ssd.py; then
    echo "PASS: PriorBox/concat/axis constant is added"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PriorBox/concat/axis constant should be added" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: tf_text_graph_ssd.py - should reshape prior boxes to 4D
if grep -q 'reshape_prior_boxes_to_4d' samples/dnn/tf_text_graph_ssd.py; then
    echo "PASS: Prior boxes are reshaped to 4D"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Prior boxes should be reshaped to 4D" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: perf_net.cpp - MobileNet_SSD_v1_TensorFlow perf test should exist
if grep -q 'PERF_TEST_P_(DNNTestNetwork, MobileNet_SSD_v1_TensorFlow)' modules/dnn/perf/perf_net.cpp; then
    echo "PASS: MobileNet_SSD_v1_TensorFlow perf test exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD_v1_TensorFlow perf test should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: perf_net.cpp - MobileNet_SSD_v2_TensorFlow perf test should exist
if grep -q 'PERF_TEST_P_(DNNTestNetwork, MobileNet_SSD_v2_TensorFlow)' modules/dnn/perf/perf_net.cpp; then
    echo "PASS: MobileNet_SSD_v2_TensorFlow perf test exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD_v2_TensorFlow perf test should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: perf_net.cpp - Inception_v2_SSD should NOT skip IE + OPENCL
if ! grep -A 3 'PERF_TEST_P_(DNNTestNetwork, Inception_v2_SSD_TensorFlow)' modules/dnn/perf/perf_net.cpp | grep -q 'backend == DNN_BACKEND_INFERENCE_ENGINE && target == DNN_TARGET_OPENCL'; then
    echo "PASS: Inception_v2_SSD_TensorFlow perf test does not skip INFERENCE_ENGINE + OPENCL"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Inception_v2_SSD_TensorFlow perf test should not skip INFERENCE_ENGINE + OPENCL" >&2
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
