#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13493: The PR itself proposes to REMOVE OpenVINO 2018 R5 workarounds
# However, for harbor testing:
# - HEAD (59ce1d80a51240dc4615ec20309a48efb95268be): Has R5 workarounds (current git state)
# - BASE (after bug.patch): R5 workarounds removed (simulates the PR changes)
# - FIXED (after fix.patch): R5 workarounds restored (back to HEAD/current git state)
#
# So "fixed" here means restoring to current HEAD, not implementing the PR's intent.

# Check 1: mvn_layer.cpp should have HAVE_INF_ENGINE ifdef
if grep -q '#ifdef HAVE_INF_ENGINE' modules/dnn/src/layers/mvn_layer.cpp && \
   grep -q 'INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2018R5)' modules/dnn/src/layers/mvn_layer.cpp; then
    echo "PASS: mvn_layer.cpp has proper HAVE_INF_ENGINE and R5 version check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp missing HAVE_INF_ENGINE ifdef or R5 version check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: onnx_importer.cpp Sub operation should properly handle blob negation
if grep -q 'Mat blob = getBlob(node_proto, constBlobs, 1);' modules/dnn/src/onnx/onnx_importer.cpp && \
   grep -q 'layerParams.set("shift", -blob.at<float>(0));' modules/dnn/src/onnx/onnx_importer.cpp && \
   grep -q 'layerParams.blobs.push_back(-1.0f \* blob.reshape(1, 1));' modules/dnn/src/onnx/onnx_importer.cpp; then
    echo "PASS: onnx_importer.cpp Sub operation handles blob negation correctly (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer.cpp Sub operation blob handling incorrect (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: onnx_importer.cpp Div operation should NOT call divide before the if statement
if ! grep -B5 'if (blob.total() == 1)' modules/dnn/src/onnx/onnx_importer.cpp | grep -A5 'layer_type == "Div"' | grep -B3 'if (blob.total() == 1)' | grep -q 'divide(1.0, blob, blob);'; then
    echo "PASS: onnx_importer.cpp Div operation has divide in correct location (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer.cpp Div operation has divide before if statement (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_backends.cpp should have R5 workaround (with 2018050000 check)
if grep -q 'INF_ENGINE_RELEASE == 2018050000' modules/dnn/test/test_backends.cpp; then
    echo "PASS: test_backends.cpp has R5 workaround (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_backends.cpp missing R5 workaround (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_ie_models.cpp should have INF_ENGINE_RELEASE == 2018050000 block
if grep -q 'INF_ENGINE_RELEASE == 2018050000' modules/dnn/test/test_ie_models.cpp; then
    echo "PASS: test_ie_models.cpp has R5-specific skip block (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_ie_models.cpp missing R5-specific skip block (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_layers.cpp should have 2018050000 skip for Eltwise test
if grep -A5 'TEST_P(Test_Caffe_layers, Eltwise)' modules/dnn/test/test_layers.cpp | grep -q '2018050000'; then
    echo "PASS: test_layers.cpp Eltwise test has R5 skip (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp Eltwise test missing R5 skip (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_onnx_importer.cpp DynamicReshape should skip for IE OpenCL
if grep -A3 'TEST_P(Test_ONNX_layers, DynamicReshape)' modules/dnn/test/test_onnx_importer.cpp | grep -q 'DNN_TARGET_OPENCL'; then
    echo "PASS: test_onnx_importer.cpp DynamicReshape skips OpenCL (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp DynamicReshape missing OpenCL skip (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_onnx_importer.cpp VGG16 should have R5-specific tolerance adjustment
if grep -A15 'TEST_P(Test_ONNX_nets, VGG16)' modules/dnn/test/test_onnx_importer.cpp | grep -q 'INF_ENGINE_RELEASE >= 2018050000'; then
    echo "PASS: test_onnx_importer.cpp VGG16 has R5-specific tolerance (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp VGG16 missing R5-specific tolerance (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_onnx_importer.cpp MobileNet_v2 should use 0.4 tolerance (not 0.38)
if grep -q 'const double l1 = (target == DNN_TARGET_OPENCL_FP16 || target == DNN_TARGET_MYRIAD) ? 0.4 : 7e-5;' modules/dnn/test/test_onnx_importer.cpp; then
    echo "PASS: test_onnx_importer.cpp MobileNet_v2 uses 0.4 tolerance (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp MobileNet_v2 tolerance incorrect (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: test_onnx_importer.cpp Emotion_ferplus should have custom tolerance handling
if grep -A5 'TEST_P(Test_ONNX_nets, Emotion_ferplus)' modules/dnn/test/test_onnx_importer.cpp | grep -q 'double l1 = default_l1;'; then
    echo "PASS: test_onnx_importer.cpp Emotion_ferplus has custom tolerance (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp Emotion_ferplus missing custom tolerance (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: test_onnx_importer.cpp Inception_v1 should have R5 skip
if grep -A5 'TEST_P(Test_ONNX_nets, Inception_v1)' modules/dnn/test/test_onnx_importer.cpp | grep -q '2018050000'; then
    echo "PASS: test_onnx_importer.cpp Inception_v1 has R5 skip (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp Inception_v1 missing R5 skip (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_torch_importer.cpp OpenFace_accuracy should have R5 in condition
if grep -A3 'TEST_P(Test_Torch_nets, OpenFace_accuracy)' modules/dnn/test/test_torch_importer.cpp | grep -q 'INF_ENGINE_RELEASE == 2018050000'; then
    echo "PASS: test_torch_importer.cpp OpenFace_accuracy has R5 in condition (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_torch_importer.cpp OpenFace_accuracy missing R5 in condition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_torch_importer.cpp FastNeuralStyle_accuracy should have R5 skip
if grep -A5 'TEST_P(Test_Torch_nets, FastNeuralStyle_accuracy)' modules/dnn/test/test_torch_importer.cpp | grep -q '2018050000'; then
    echo "PASS: test_torch_importer.cpp FastNeuralStyle_accuracy has R5 skip (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_torch_importer.cpp FastNeuralStyle_accuracy missing R5 skip (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: test_tf_importer.cpp leaky_relu should have R5 skip
if grep -A5 'TEST_P(Test_TensorFlow_layers, leaky_relu)' modules/dnn/test/test_tf_importer.cpp | grep -q '2018050000'; then
    echo "PASS: test_tf_importer.cpp leaky_relu has R5 skip (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp leaky_relu missing R5 skip (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: test_tf_importer.cpp MobileNet_v1_SSD_PPN should have R5 skip
if grep -A5 'TEST_P(Test_TensorFlow_nets, MobileNet_v1_SSD_PPN)' modules/dnn/test/test_tf_importer.cpp | grep -q '2018050000'; then
    echo "PASS: test_tf_importer.cpp MobileNet_v1_SSD_PPN has R5 skip (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp MobileNet_v1_SSD_PPN missing R5 skip (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: test_tf_importer.cpp slice should have R5 skip
if grep -A10 'TEST_P(Test_TensorFlow_layers, slice)' modules/dnn/test/test_tf_importer.cpp | grep -q '2018050000'; then
    echo "PASS: test_tf_importer.cpp slice has R5 skip (fixed version - HEAD state)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp slice missing R5 skip (buggy version)" >&2
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
