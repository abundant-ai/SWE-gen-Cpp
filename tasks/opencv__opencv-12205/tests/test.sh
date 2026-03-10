#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12205: Fix quantized TensorFlow face detection for Inference Engine backend on non-CPU targets
# The fix uses SpaceToBatchND instead of Pad operations and improves backend support

# Check 1: quantize_face_detector.py should use space_to_batch_nd with name='Pad'
if grep -q "data_scale = tf.space_to_batch_nd(data_scale, \[1, 1\], \[\[3, 3\], \[3, 3\]\], name='Pad')" modules/dnn/misc/quantize_face_detector.py; then
    echo "PASS: quantize_face_detector.py uses space_to_batch_nd for first Pad"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: quantize_face_detector.py should use space_to_batch_nd for first Pad" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: quantize_face_detector.py should use space_to_batch_nd with name='Pad_1'
if grep -q "layer_256_1_conv1 = tf.space_to_batch_nd(layer_256_1_relu1, \[1, 1\], \[\[1, 1\], \[1, 1\]\], name='Pad_1')" modules/dnn/misc/quantize_face_detector.py; then
    echo "PASS: quantize_face_detector.py uses space_to_batch_nd for Pad_1"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: quantize_face_detector.py should use space_to_batch_nd for Pad_1" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: quantize_face_detector.py should use space_to_batch_nd with name='Pad_2'
if grep -q "conv7_2_h = tf.space_to_batch_nd(conv7_1_h, \[1, 1\], \[\[1, 1\], \[1, 1\]\], name='Pad_2')" modules/dnn/misc/quantize_face_detector.py; then
    echo "PASS: quantize_face_detector.py uses space_to_batch_nd for Pad_2"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: quantize_face_detector.py should use space_to_batch_nd for Pad_2" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: quantize_face_detector.py should set preferrable backend to OPENCV
if grep -q 'cvNet.setPreferableBackend(cv.dnn.DNN_BACKEND_OPENCV)' modules/dnn/misc/quantize_face_detector.py; then
    echo "PASS: quantize_face_detector.py sets OPENCV backend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: quantize_face_detector.py should set OPENCV backend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: quantize_face_detector.py should include Tblock_shape and Tcrops in attributes
if grep -q "'Tpaddings', 'Tblock_shape', 'Tcrops'\]" modules/dnn/misc/quantize_face_detector.py; then
    echo "PASS: quantize_face_detector.py includes Tblock_shape and Tcrops attributes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: quantize_face_detector.py should include Tblock_shape and Tcrops attributes" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: normalize_bbox_layer.cpp should have improved supportBackend implementation
if grep -A 8 'virtual bool supportBackend(int backendId) CV_OVERRIDE' modules/dnn/src/layers/normalize_bbox_layer.cpp | grep -q 'if (backendId == DNN_BACKEND_INFERENCE_ENGINE)'; then
    echo "PASS: normalize_bbox_layer.cpp has improved supportBackend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp should have improved supportBackend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: normalize_bbox_layer.cpp should check preferableTarget == DNN_TARGET_MYRIAD
if grep -q 'if (preferableTarget == DNN_TARGET_MYRIAD)' modules/dnn/src/layers/normalize_bbox_layer.cpp; then
    echo "PASS: normalize_bbox_layer.cpp checks for MYRIAD target"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp should check for MYRIAD target" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: normalize_bbox_layer.cpp should have finalize method
if grep -q 'void finalize(const std::vector<Mat\*> &inputs, std::vector<Mat> &outputs) CV_OVERRIDE' modules/dnn/src/layers/normalize_bbox_layer.cpp; then
    echo "PASS: normalize_bbox_layer.cpp has finalize method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp should have finalize method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: normalize_bbox_layer.cpp initInfEngine should handle input dims
if grep -A 5 'virtual Ptr<BackendNode> initInfEngine' modules/dnn/src/layers/normalize_bbox_layer.cpp | grep -q 'InferenceEngine::DataPtr input = infEngineDataNode(inputs\[0\])'; then
    echo "PASS: normalize_bbox_layer.cpp initInfEngine handles input dimensions"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp initInfEngine should handle input dimensions" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: normalize_bbox_layer.cpp should support both Normalize and GRN layer types
if grep -q 'lp.type = "GRN"' modules/dnn/src/layers/normalize_bbox_layer.cpp; then
    echo "PASS: normalize_bbox_layer.cpp supports GRN layer type"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp should support GRN layer type" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: tf_importer.cpp should have detailed error message
if grep -q 'CV_Error(Error::StsError, "Input \[" + layer.input(input_blob_index) +' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp has detailed error message"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should have detailed error message" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: tf_importer.cpp should conditionally call setPadding
if grep -q 'if (!layerParams.has("pad_w") && !layerParams.has("pad_h"))' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp conditionally calls setPadding"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should conditionally call setPadding" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: tf_importer.cpp should NOT set pad_mode to empty string
if ! grep -A 3 'if (!next_layers.empty())' modules/dnn/src/tensorflow/tf_importer.cpp | grep -q 'layerParams.set("pad_mode", "")'; then
    echo "PASS: tf_importer.cpp does not set empty pad_mode"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should not set empty pad_mode" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: opencv_face_detector.pbtxt should use SpaceToBatchND for Pad operation
if grep -A 3 'name: "Pad"' samples/dnn/face_detector/opencv_face_detector.pbtxt | grep -q 'op: "SpaceToBatchND"'; then
    echo "PASS: opencv_face_detector.pbtxt uses SpaceToBatchND for Pad"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv_face_detector.pbtxt should use SpaceToBatchND for Pad" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: opencv_face_detector.pbtxt should have SpaceToBatchND/block_shape node
if grep -q 'name: "SpaceToBatchND/block_shape"' samples/dnn/face_detector/opencv_face_detector.pbtxt; then
    echo "PASS: opencv_face_detector.pbtxt has SpaceToBatchND/block_shape node"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv_face_detector.pbtxt should have SpaceToBatchND/block_shape node" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: opencv_face_detector.pbtxt should have BatchToSpaceND nodes
batchToSpace_count=$(grep -c 'op: "BatchToSpaceND"' samples/dnn/face_detector/opencv_face_detector.pbtxt || echo 0)
if [ "$batchToSpace_count" -ge 3 ]; then
    echo "PASS: opencv_face_detector.pbtxt has BatchToSpaceND nodes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv_face_detector.pbtxt should have BatchToSpaceND nodes (found $batchToSpace_count)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: test_tf_importer.cpp should skip non-CPU targets for l2_normalize_3d
if grep -A 2 'TEST_P(Test_TensorFlow_layers, l2_normalize_3d)' modules/dnn/test/test_tf_importer.cpp | grep -q 'if (backend == DNN_BACKEND_INFERENCE_ENGINE && target != DNN_TARGET_CPU)'; then
    echo "PASS: test_tf_importer.cpp skips non-CPU targets for l2_normalize_3d"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should skip non-CPU targets for l2_normalize_3d" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: test_tf_importer.cpp should NOT have IE backend skip for opencv_face_detector_uint8
if ! grep -A 5 'TEST_P(Test_TensorFlow_nets, opencv_face_detector_uint8)' modules/dnn/test/test_tf_importer.cpp | grep -q 'if (backend == DNN_BACKEND_INFERENCE_ENGINE &&'; then
    echo "PASS: test_tf_importer.cpp does not skip IE backend for opencv_face_detector_uint8"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should not skip IE backend for opencv_face_detector_uint8" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 19: test_tf_importer.cpp should use 0.024 for iouDiff on FP16/Myriad
if grep -q 'double iouDiff = (target == DNN_TARGET_OPENCL_FP16 || target == DNN_TARGET_MYRIAD) ? 0.024 : 1e-2;' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp uses 0.024 for iouDiff"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should use 0.024 for iouDiff" >&2
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
