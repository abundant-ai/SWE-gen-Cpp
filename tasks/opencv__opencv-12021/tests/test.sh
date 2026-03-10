#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12021: Fix TensorFlow SSD models coordinate layout handling for Inference Engine backend

# Check 1: tf_importer.cpp should have locPredTransposed attribute handling
if grep -q "bool locPredTransposed = hasLayerAttr(layer, \"loc_pred_transposed\")" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "getLayerAttr(layer, \"loc_pred_transposed\").b();" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp has locPredTransposed attribute handling"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should have locPredTransposed attribute handling" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tf_importer.cpp should shuffle bias from yxYX to xyXY when locPredTransposed
if grep -q "// Shuffle bias from yxYX to xyXY." modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "if (locPredTransposed)" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp shuffles bias for transposed coordinates"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should shuffle bias for transposed coordinates" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_importer.cpp should shuffle output channels from yxYX to xyXY
if grep -q "// Shuffle output channels from yxYX to xyXY." modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "std::swap_ranges(src.begin<float>(), src.end<float>(), dst.begin<float>());" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp shuffles output channels for transposed coordinates"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should shuffle output channels for transposed coordinates" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tf_importer.cpp should declare variables outCh, inCh, height, width
if grep -q "const int outCh = kshape\[0\];" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "const int inCh = kshape\[1\];" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "const int height = kshape\[2\];" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "const int width = kshape\[3\];" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp declares convolution dimension variables"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should declare convolution dimension variables" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: tf_importer.cpp should use named variables for layerParams
if grep -q "layerParams.set(\"kernel_h\", height);" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "layerParams.set(\"kernel_w\", width);" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null && \
   grep -q "layerParams.set(\"num_output\", outCh);" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp uses named variables for layer parameters"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should use named variables for layer parameters" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: tf_importer.cpp should have CV_Assert for locPredTransposed in DepthwiseConv2dNative
if grep -q "CV_Assert(!locPredTransposed);" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp asserts locPredTransposed not used with DepthwiseConv2dNative"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should assert locPredTransposed not used with DepthwiseConv2dNative" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_tf_importer.cpp should have iouDiff threshold of 0.09 (original/fixed value)
if grep -q 'double iouDiff = (target == DNN_TARGET_OPENCL_FP16 || target == DNN_TARGET_MYRIAD) ? 0.09 : default_lInf;' modules/dnn/test/test_tf_importer.cpp 2>/dev/null; then
    echo "PASS: test_tf_importer.cpp has iouDiff threshold of 0.09"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should have iouDiff threshold of 0.09" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: tf_text_graph_ssd.py should set loc_pred_transposed on BoxEncodingPredictor Conv2D nodes
if grep -q 'text_format.Merge' samples/dnn/tf_text_graph_ssd.py 2>/dev/null && \
   grep -q 'loc_pred_transposed' samples/dnn/tf_text_graph_ssd.py 2>/dev/null && \
   grep -q 'BoxPredictor' samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py sets loc_pred_transposed attribute"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should set loc_pred_transposed attribute" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: tf_text_graph_ssd.py should use concat/axis_flatten for PriorBox concat
if grep -q "addConcatNode('PriorBox/concat', priorBoxes, 'concat/axis_flatten')" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py uses concat/axis_flatten for PriorBox"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should use concat/axis_flatten for PriorBox" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: tf_text_graph_ssd.py should NOT have reshape_prior_boxes_to_4d constant
if ! grep -q "addConstNode('reshape_prior_boxes_to_4d'" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py does not have reshape_prior_boxes_to_4d constant"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should not have reshape_prior_boxes_to_4d constant" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: tf_text_graph_ssd.py should NOT have reshape to 4d nodes
if ! grep -q "reshape.name = priorBox.name + '/4d'" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py does not create 4d reshape nodes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should not create 4d reshape nodes" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: tf_text_graph_ssd.py should NOT set loc_pred_transposed on DetectionOutput at the end
if ! grep -q "detectionOut.attr\[.loc_pred_transposed.\]" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py does not set loc_pred_transposed on DetectionOutput"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should not set loc_pred_transposed on DetectionOutput" >&2
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
