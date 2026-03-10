#!/bin/bash

cd /app/src

# Apply fix.patch to get HEAD state for source code validation
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_darknet_importer.cpp" "modules/dnn/test/test_darknet_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #11785: Add support for avgpool/softmax layers in Darknet, ClipByValue in TensorFlow, and configurable DNN backend

# Check 1: darknet_io.cpp - setAvgpool() function should be declared
if grep -q 'void setAvgpool()' modules/dnn/src/darknet/darknet_io.cpp; then
    echo "PASS: setAvgpool() function is declared in darknet_io.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setAvgpool() function should be declared in darknet_io.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: darknet_io.cpp - setAvgpool() should set pool parameter to "ave"
if grep -A 5 'void setAvgpool()' modules/dnn/src/darknet/darknet_io.cpp | grep -q 'avgpool_param.set<cv::String>("pool", "ave")'; then
    echo "PASS: setAvgpool() sets pool parameter to 'ave'"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setAvgpool() should set pool parameter to 'ave'" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: darknet_io.cpp - setAvgpool() should enable global pooling
if grep -A 5 'void setAvgpool()' modules/dnn/src/darknet/darknet_io.cpp | grep -q 'avgpool_param.set<bool>("global_pooling", true)'; then
    echo "PASS: setAvgpool() enables global pooling"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setAvgpool() should enable global pooling" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: darknet_io.cpp - setSoftmax() function should be declared
if grep -q 'void setSoftmax()' modules/dnn/src/darknet/darknet_io.cpp; then
    echo "PASS: setSoftmax() function is declared in darknet_io.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setSoftmax() function should be declared in darknet_io.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: darknet_io.cpp - avgpool layer type should be handled
if grep -q 'else if (layer_type == "avgpool")' modules/dnn/src/darknet/darknet_io.cpp; then
    echo "PASS: avgpool layer type is handled in darknet_io.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: avgpool layer type should be handled in darknet_io.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: darknet_io.cpp - avgpool handling should call setAvgpool()
if grep -A 3 'else if (layer_type == "avgpool")' modules/dnn/src/darknet/darknet_io.cpp | grep -q 'setParams.setAvgpool()'; then
    echo "PASS: avgpool handler calls setAvgpool()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: avgpool handler should call setAvgpool()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: darknet_io.cpp - softmax layer type should be handled
if grep -q 'else if (layer_type == "softmax")' modules/dnn/src/darknet/darknet_io.cpp; then
    echo "PASS: softmax layer type is handled in darknet_io.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax layer type should be handled in darknet_io.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: darknet_io.cpp - softmax handling should call setSoftmax()
if grep -A 5 'else if (layer_type == "softmax")' modules/dnn/src/darknet/darknet_io.cpp | grep -q 'setParams.setSoftmax()'; then
    echo "PASS: softmax handler calls setSoftmax()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax handler should call setSoftmax()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: tf_importer.cpp - ClipByValue operation should be handled
if grep -q 'type == "ClipByValue"' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: ClipByValue operation is handled in tf_importer.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ClipByValue operation should be handled in tf_importer.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: tf_importer.cpp - ClipByValue should set min_value parameter
if grep -A 20 'type == "ClipByValue"' modules/dnn/src/tensorflow/tf_importer.cpp | grep -q 'layerParams.set("min_value"'; then
    echo "PASS: ClipByValue sets min_value parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ClipByValue should set min_value parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: tf_importer.cpp - ClipByValue should set max_value parameter
if grep -A 20 'type == "ClipByValue"' modules/dnn/src/tensorflow/tf_importer.cpp | grep -q 'layerParams.set("max_value"'; then
    echo "PASS: ClipByValue sets max_value parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ClipByValue should set max_value parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: tf_importer.cpp - ClipByValue should create ReLU6 layer
if grep -A 20 'type == "ClipByValue"' modules/dnn/src/tensorflow/tf_importer.cpp | grep -q 'dstNet.addLayer(name, "ReLU6"'; then
    echo "PASS: ClipByValue creates ReLU6 layer"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ClipByValue should create ReLU6 layer" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: dnn.cpp - PARAM_DNN_BACKEND_DEFAULT variable should be declared
if grep -q 'static int PARAM_DNN_BACKEND_DEFAULT' modules/dnn/src/dnn.cpp; then
    echo "PASS: PARAM_DNN_BACKEND_DEFAULT variable is declared in dnn.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PARAM_DNN_BACKEND_DEFAULT variable should be declared in dnn.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: dnn.cpp - PARAM_DNN_BACKEND_DEFAULT should use getConfigurationParameterSizeT
if grep -A 2 'static int PARAM_DNN_BACKEND_DEFAULT' modules/dnn/src/dnn.cpp | grep -q 'utils::getConfigurationParameterSizeT("OPENCV_DNN_BACKEND_DEFAULT"'; then
    echo "PASS: PARAM_DNN_BACKEND_DEFAULT uses getConfigurationParameterSizeT"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PARAM_DNN_BACKEND_DEFAULT should use getConfigurationParameterSizeT" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: dnn.cpp - Default backend should use PARAM_DNN_BACKEND_DEFAULT
if grep -A 2 'if (preferableBackend == DNN_BACKEND_DEFAULT)' modules/dnn/src/dnn.cpp | grep -q 'preferableBackend = (Backend)PARAM_DNN_BACKEND_DEFAULT'; then
    echo "PASS: Default backend uses PARAM_DNN_BACKEND_DEFAULT"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Default backend should use PARAM_DNN_BACKEND_DEFAULT" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: test_darknet_importer.cpp - avgpool_softmax test should be present
if grep -q 'TEST(Test_Darknet, avgpool_softmax)' modules/dnn/test/test_darknet_importer.cpp; then
    echo "PASS: avgpool_softmax test is present in test_darknet_importer.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: avgpool_softmax test should be present in test_darknet_importer.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: test_tf_importer.cpp - relu6 test should call runTensorFlowNet with hasText parameter
if grep -A 5 'TEST(Test_TensorFlow, relu6)' modules/dnn/test/test_tf_importer.cpp | grep -q 'hasText'; then
    echo "PASS: relu6 test calls runTensorFlowNet with hasText parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: relu6 test should call runTensorFlowNet with hasText parameter" >&2
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
