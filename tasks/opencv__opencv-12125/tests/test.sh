#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12125: Support for shared weights in convolution layers and weight-shared convolutional box predictor
# The fix adds sharedWeights map and logic to reuse kernel weights, plus box_predictor argument support

# Check 1: tf_importer.cpp should have sharedWeights map declaration
if grep -q "std::map<String, Mat> sharedWeights;" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp has sharedWeights map declaration"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should have sharedWeights map declaration" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tf_importer.cpp should get kernelTensorInpId
if grep -q "int kernelTensorInpId = -1;" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp declares kernelTensorInpId"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should declare kernelTensorInpId" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_importer.cpp should call getConstBlob with kernelTensorInpId parameter
if grep -q "getConstBlob(layer, value_id, -1, &kernelTensorInpId)" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp calls getConstBlob with kernelTensorInpId"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should call getConstBlob with kernelTensorInpId" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tf_importer.cpp should get kernelTensorName from layer.input
if grep -q "const String kernelTensorName = layer.input(kernelTensorInpId);" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp gets kernelTensorName from layer.input"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should get kernelTensorName from layer.input" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: tf_importer.cpp should check if weight is already in sharedWeights map
if grep -q "std::map<String, Mat>::iterator sharedWeightsIt = sharedWeights.find(kernelTensorName);" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp checks sharedWeights map for existing weights"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should check sharedWeights map for existing weights" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: tf_importer.cpp should have conditional logic for new vs shared weights
if grep -q "if (sharedWeightsIt == sharedWeights.end())" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp has conditional logic for new vs shared weights"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should have conditional logic for new vs shared weights" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: tf_importer.cpp should store weights in sharedWeights map
if grep -q "sharedWeights\[kernelTensorName\] = layerParams.blobs\[0\];" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp stores weights in sharedWeights map"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should store weights in sharedWeights map" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: tf_importer.cpp should reuse weights from sharedWeights in else branch
if grep -q "layerParams.blobs\[0\] = sharedWeightsIt->second;" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp reuses weights from sharedWeights map"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should reuse weights from sharedWeights map" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: tf_importer.cpp should use layerParams.blobs[0].size[2] for kernel_h
if grep -q "layerParams.set(\"kernel_h\", layerParams.blobs\[0\].size\[2\]);" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp uses layerParams.blobs[0].size[2] for kernel_h"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should use layerParams.blobs[0].size[2] for kernel_h" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: tf_text_graph_ssd.py should have box_predictor argument
if grep -q "parser.add_argument('--box_predictor', default='convolutional', type=str," samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py has box_predictor argument"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should have box_predictor argument" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: tf_text_graph_ssd.py should have not_reduce_boxes_in_lowest_layer argument
if grep -q "parser.add_argument('--not_reduce_boxes_in_lowest_layer', default=False, action='store_true'," samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py has not_reduce_boxes_in_lowest_layer argument"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should have not_reduce_boxes_in_lowest_layer argument" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: tf_text_graph_ssd.py should use conditional label based on box_predictor
if grep -q "for label in \['ClassPredictor', 'BoxEncodingPredictor' if args.box_predictor is 'convolutional' else 'BoxPredictor'\]:" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py uses conditional label based on box_predictor"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should use conditional label based on box_predictor" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: tf_text_graph_ssd.py should have conditional input name based on box_predictor
if grep -q "if args.box_predictor is 'convolutional':" samples/dnn/tf_text_graph_ssd.py 2>/dev/null && \
   grep -q "inpName = 'BoxPredictor_%d/%s/BiasAdd' % (i, label)" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py has conditional input name based on box_predictor"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should have conditional input name based on box_predictor" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: tf_text_graph_ssd.py should handle WeightSharedConvolutionalBoxPredictor
if grep -q "inpName = 'WeightSharedConvolutionalBoxPredictor/%s/BiasAdd' % label" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py handles WeightSharedConvolutionalBoxPredictor"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should handle WeightSharedConvolutionalBoxPredictor" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: tf_text_graph_ssd.py should use not_reduce_boxes_in_lowest_layer in condition
if grep -q "if i == 0 and not args.not_reduce_boxes_in_lowest_layer:" samples/dnn/tf_text_graph_ssd.py 2>/dev/null; then
    echo "PASS: tf_text_graph_ssd.py uses not_reduce_boxes_in_lowest_layer in condition"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should use not_reduce_boxes_in_lowest_layer in condition" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: tf_text_graph_ssd.py should have conditional detectionOut input based on box_predictor
if grep -q "if args.box_predictor == 'convolutional':" samples/dnn/tf_text_graph_ssd.py 2>/dev/null && \
   grep -A 2 "if args.box_predictor == 'convolutional':" samples/dnn/tf_text_graph_ssd.py 2>/dev/null | grep -q "detectionOut.input.append('BoxEncodingPredictor/concat')"; then
    echo "PASS: tf_text_graph_ssd.py has conditional detectionOut input based on box_predictor"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should have conditional detectionOut input based on box_predictor" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: test_tf_importer.cpp should have MobileNet_v1_SSD_PPN test (added in fix)
if grep -q "TEST_P(Test_TensorFlow_nets, MobileNet_v1_SSD_PPN)" modules/dnn/test/test_tf_importer.cpp 2>/dev/null; then
    echo "PASS: test_tf_importer.cpp has MobileNet_v1_SSD_PPN test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should have MobileNet_v1_SSD_PPN test" >&2
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
