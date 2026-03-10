#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #11970: Fix OpenCL execution in TensorFlow DNN models

# Check 1: detection_output_layer.cpp should have proper 2D reshape with shape array
if grep -A2 'confPreds.push_back' modules/dnn/src/layers/detection_output_layer.cpp 2>/dev/null | grep -q 'shape\[0\] = num \* numPredsPerClass;'; then
    echo "PASS: detection_output_layer.cpp has proper shape calculation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should calculate shape[0] = num * numPredsPerClass" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: detection_output_layer.cpp should calculate shape[1]
if grep -q 'shape\[1\] = inp1.total() / shape\[0\];' modules/dnn/src/layers/detection_output_layer.cpp 2>/dev/null; then
    echo "PASS: detection_output_layer.cpp calculates shape[1]"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should calculate shape[1] = inp1.total() / shape[0]" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: detection_output_layer.cpp should use 2D reshape
if grep -q 'inp1.reshape(1, 2, &shape\[0\])' modules/dnn/src/layers/detection_output_layer.cpp 2>/dev/null; then
    echo "PASS: detection_output_layer.cpp uses 2D reshape with shape array"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should use inp1.reshape(1, 2, &shape[0])" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: detection_output_layer.cpp should NOT use simple 1D reshape
if ! grep -q 'inp1.reshape(1, num \* numPredsPerClass)' modules/dnn/src/layers/detection_output_layer.cpp 2>/dev/null; then
    echo "PASS: detection_output_layer.cpp does not use incorrect 1D reshape"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should not use simple 1D reshape" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: detection_output_layer.cpp should pass _clip parameter
if grep -q '_codeType, _varianceEncodedInTarget, _clip,' modules/dnn/src/layers/detection_output_layer.cpp 2>/dev/null; then
    echo "PASS: detection_output_layer.cpp passes _clip parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should pass _clip parameter (not hardcoded false)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: softmax_layer.cpp should declare src and dstMat early
if grep -B5 'if (softmaxOp.empty())' modules/dnn/src/layers/softmax_layer.cpp 2>/dev/null | grep -q 'UMat& src = inputs\[0\];'; then
    echo "PASS: softmax_layer.cpp declares src early"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax_layer.cpp should declare src before softmaxOp.empty() check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: softmax_layer.cpp should declare dstMat early
if grep -B5 'if (softmaxOp.empty())' modules/dnn/src/layers/softmax_layer.cpp 2>/dev/null | grep -q 'UMat& dstMat = outputs\[0\];'; then
    echo "PASS: softmax_layer.cpp declares dstMat early"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax_layer.cpp should declare dstMat before softmaxOp.empty() check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: softmax_layer.cpp should declare axis early
if grep -B5 'if (softmaxOp.empty())' modules/dnn/src/layers/softmax_layer.cpp 2>/dev/null | grep -q 'int axis = clamp(axisRaw, src.dims);'; then
    echo "PASS: softmax_layer.cpp declares axis early with clamp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax_layer.cpp should declare axis early with clamp(axisRaw, src.dims)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: softmax_layer.cpp should use axis (not axisRaw) in config
if grep -A10 'if (softmaxOp.empty())' modules/dnn/src/layers/softmax_layer.cpp 2>/dev/null | grep -q 'config.axis = axis;'; then
    echo "PASS: softmax_layer.cpp uses clamped axis in config"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax_layer.cpp should use config.axis = axis (not axisRaw)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: softmax_layer.cpp should use axis for channels
if grep -A10 'if (softmaxOp.empty())' modules/dnn/src/layers/softmax_layer.cpp 2>/dev/null | grep -q 'config.channels = inputs\[0\].size\[axis\];'; then
    echo "PASS: softmax_layer.cpp uses axis for channels"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax_layer.cpp should use inputs[0].size[axis] for channels" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: softmax_layer.cpp should NOT use axisRaw in config
if ! grep -A10 'if (softmaxOp.empty())' modules/dnn/src/layers/softmax_layer.cpp 2>/dev/null | grep -q 'config.axis = axisRaw;'; then
    echo "PASS: softmax_layer.cpp does not use axisRaw in config"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax_layer.cpp should not use axisRaw in config" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_tf_importer.cpp should use class-based Test_TensorFlow_nets
if grep -q 'class Test_TensorFlow_nets : public DNNTestLayer' modules/dnn/test/test_tf_importer.cpp 2>/dev/null; then
    echo "PASS: test_tf_importer.cpp uses class-based test structure"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should use 'class Test_TensorFlow_nets : public DNNTestLayer'" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_tf_importer.cpp should NOT use typedef
if ! grep -q 'typedef testing::TestWithParam<Target> Test_TensorFlow_nets;' modules/dnn/test/test_tf_importer.cpp 2>/dev/null; then
    echo "PASS: test_tf_importer.cpp does not use typedef"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should not use typedef for Test_TensorFlow_nets" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: MobileNet_SSD test should have checkBackend call
if grep -A5 'TEST_P(Test_TensorFlow_nets, MobileNet_SSD)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'checkBackend();'; then
    echo "PASS: MobileNet_SSD has checkBackend call"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD should call checkBackend()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: MobileNet_SSD should have backend skip conditions
if grep -A10 'TEST_P(Test_TensorFlow_nets, MobileNet_SSD)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: MobileNet_SSD has backend skip conditions"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD should have backend/target skip conditions" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: MobileNet_SSD should use 'refs' variable name
if grep -A20 'TEST_P(Test_TensorFlow_nets, MobileNet_SSD)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'std::vector<Mat> refs'; then
    echo "PASS: MobileNet_SSD uses 'refs' variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD should use 'refs' not 'target' for reference data" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: MobileNet_SSD should use backend/target variables
if grep -A30 'TEST_P(Test_TensorFlow_nets, MobileNet_SSD)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'net.setPreferableBackend(backend);'; then
    echo "PASS: MobileNet_SSD uses backend variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD should use net.setPreferableBackend(backend)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: MobileNet_SSD should set target from variable
if grep -A30 'TEST_P(Test_TensorFlow_nets, MobileNet_SSD)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'net.setPreferableTarget(target);'; then
    echo "PASS: MobileNet_SSD sets target from variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD should use net.setPreferableTarget(target) not GetParam()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 19: Inception_v2_SSD should have checkBackend call
if grep -A5 'TEST_P(Test_TensorFlow_nets, Inception_v2_SSD)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'checkBackend();'; then
    echo "PASS: Inception_v2_SSD has checkBackend call"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Inception_v2_SSD should call checkBackend()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 20: Inception_v2_SSD should have scoreDiff/iouDiff tolerance handling
if grep -A50 'TEST_P(Test_TensorFlow_nets, Inception_v2_SSD)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'double scoreDiff'; then
    echo "PASS: Inception_v2_SSD has scoreDiff tolerance"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Inception_v2_SSD should have scoreDiff/iouDiff tolerance for different targets" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 21: Inception_v2_Faster_RCNN should have skip conditions
if grep -A10 'TEST_P(Test_TensorFlow_nets, Inception_v2_Faster_RCNN)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: Inception_v2_Faster_RCNN has skip conditions"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Inception_v2_Faster_RCNN should have backend skip conditions" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 22: opencv_face_detector_uint8 should have checkBackend
if grep -A5 'TEST_P(Test_TensorFlow_nets, opencv_face_detector_uint8)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'checkBackend();'; then
    echo "PASS: opencv_face_detector_uint8 has checkBackend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv_face_detector_uint8 should call checkBackend()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 23: opencv_face_detector_uint8 should have tolerance handling
if grep -A50 'TEST_P(Test_TensorFlow_nets, opencv_face_detector_uint8)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'double scoreDiff'; then
    echo "PASS: opencv_face_detector_uint8 has scoreDiff tolerance"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv_face_detector_uint8 should have scoreDiff/iouDiff tolerance" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 24: EAST_text_detection should have checkBackend
if grep -A5 'TEST_P(Test_TensorFlow_nets, EAST_text_detection)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'checkBackend();'; then
    echo "PASS: EAST_text_detection has checkBackend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: EAST_text_detection should call checkBackend()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 25: EAST_text_detection should have skip conditions
if grep -A10 'TEST_P(Test_TensorFlow_nets, EAST_text_detection)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q 'DNN_TARGET_OPENCL_FP16'; then
    echo "PASS: EAST_text_detection has skip conditions"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: EAST_text_detection should have target skip conditions" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 26: Should use dnnBackendsAndTargets() not availableDnnTargets()
if grep -q 'INSTANTIATE_TEST_CASE_P(/\*\*/, Test_TensorFlow_nets, dnnBackendsAndTargets());' modules/dnn/test/test_tf_importer.cpp 2>/dev/null; then
    echo "PASS: Uses dnnBackendsAndTargets() for test instantiation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Should use dnnBackendsAndTargets() not availableDnnTargets()" >&2
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
