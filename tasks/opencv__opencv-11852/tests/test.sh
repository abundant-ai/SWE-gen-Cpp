#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #11852: Fix IR model output layer metadata and NMS application

# Check 1: dnn.cpp - Should have cvLayer variable to store layer name and type
if grep -A 5 'for (auto& it : ieNet.getOutputsInfo())' modules/dnn/src/dnn.cpp | grep -q 'Ptr<Layer> cvLayer(new InfEngineBackendLayer(it.second))'; then
    echo "PASS: dnn.cpp creates cvLayer to store output layer metadata"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should create cvLayer variable for output layer metadata" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.cpp - Should get ieLayer by name to extract type information
if grep -A 7 'for (auto& it : ieNet.getOutputsInfo())' modules/dnn/src/dnn.cpp | grep -q 'InferenceEngine::CNNLayerPtr ieLayer = ieNet.getLayerByName(it.first.c_str())'; then
    echo "PASS: dnn.cpp retrieves ieLayer to get type information"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should retrieve ieLayer by name" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp - Should set cvLayer->name from it.first
if grep -A 10 'for (auto& it : ieNet.getOutputsInfo())' modules/dnn/src/dnn.cpp | grep -q 'cvLayer->name = it.first'; then
    echo "PASS: dnn.cpp sets cvLayer->name from output info"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should set cvLayer->name" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn.cpp - Should set cvLayer->type from ieLayer->type
if grep -A 12 'for (auto& it : ieNet.getOutputsInfo())' modules/dnn/src/dnn.cpp | grep -q 'cvLayer->type = ieLayer->type'; then
    echo "PASS: dnn.cpp sets cvLayer->type from ieLayer"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should set cvLayer->type" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dnn.cpp - Should assign cvLayer to ld.layerInstance
if grep -A 12 'for (auto& it : ieNet.getOutputsInfo())' modules/dnn/src/dnn.cpp | grep -q 'ld.layerInstance = cvLayer'; then
    echo "PASS: dnn.cpp assigns cvLayer to layerInstance"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should assign cvLayer to ld.layerInstance" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_layers.cpp - Should verify output layer name
if grep -A 5 'normAssert(outDefault, out);' modules/dnn/test/test_layers.cpp | grep -q 'ASSERT_EQ(net.getLayer(outLayers\[0\])->name, "output_merge")'; then
    echo "PASS: test_layers.cpp verifies output layer name"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp should verify output layer name is 'output_merge'" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_layers.cpp - Should verify output layer type
if grep -A 5 'normAssert(outDefault, out);' modules/dnn/test/test_layers.cpp | grep -q 'ASSERT_EQ(net.getLayer(outLayers\[0\])->type, "Concat")'; then
    echo "PASS: test_layers.cpp verifies output layer type"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp should verify output layer type is 'Concat'" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: object_detection.cpp - Should have duplicate thr parameter (second one is for NMS threshold)
# Note: The fix has a bug where both parameters use "thr" key instead of separate "nms" key
if grep 'const char\* keys' -A 30 samples/dnn/object_detection.cpp | grep -c '{ thr' | grep -q '2'; then
    echo "PASS: object_detection.cpp has two thr parameters (confidence and NMS thresholds)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: object_detection.cpp should have duplicate thr parameter for NMS threshold" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: object_detection.cpp - Should declare nmsThreshold variable
if grep -q 'float confThreshold, nmsThreshold;' samples/dnn/object_detection.cpp; then
    echo "PASS: object_detection.cpp declares nmsThreshold variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: object_detection.cpp should declare nmsThreshold variable" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: object_detection.cpp - Should parse nmsThreshold from command line
if grep -q 'nmsThreshold = parser.get<float>("nms")' samples/dnn/object_detection.cpp; then
    echo "PASS: object_detection.cpp parses nmsThreshold from command line"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: object_detection.cpp should parse nmsThreshold" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: object_detection.cpp - Should declare classIds, confidences, boxes at function start
if grep -B 5 'if (net.getLayer(0)->outputNameToIndex("im_info") != -1)' samples/dnn/object_detection.cpp | grep -q 'std::vector<int> classIds;' && \
   grep -B 5 'if (net.getLayer(0)->outputNameToIndex("im_info") != -1)' samples/dnn/object_detection.cpp | grep -q 'std::vector<float> confidences;' && \
   grep -B 5 'if (net.getLayer(0)->outputNameToIndex("im_info") != -1)' samples/dnn/object_detection.cpp | grep -q 'std::vector<Rect> boxes;'; then
    echo "PASS: object_detection.cpp declares classIds, confidences, boxes at function start"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: object_detection.cpp should declare classIds, confidences, boxes before if statement" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: object_detection.cpp - Faster-RCNN should accumulate boxes instead of drawing directly
if grep -A 25 'if (net.getLayer(0)->outputNameToIndex("im_info") != -1)' samples/dnn/object_detection.cpp | grep -q 'classIds.push_back((int)(data\[i + 1\]) - 1)' && \
   grep -A 25 'if (net.getLayer(0)->outputNameToIndex("im_info") != -1)' samples/dnn/object_detection.cpp | grep -q 'boxes.push_back(Rect(left, top, width, height))' && \
   grep -A 25 'if (net.getLayer(0)->outputNameToIndex("im_info") != -1)' samples/dnn/object_detection.cpp | grep -q 'confidences.push_back(confidence)'; then
    echo "PASS: object_detection.cpp accumulates detections for Faster-RCNN"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: object_detection.cpp should accumulate boxes for Faster-RCNN instead of drawing directly" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: object_detection.cpp - Should have global NMSBoxes call after all detection types
if grep -A 50 'else if (outLayerType == "Region")' samples/dnn/object_detection.cpp | tail -20 | grep -q 'NMSBoxes(boxes, confidences, confThreshold, nmsThreshold, indices)'; then
    echo "PASS: object_detection.cpp applies NMS globally after all detection processing"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: object_detection.cpp should apply NMS after all detection types" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: object_detection.cpp - NMS should NOT be inside Region block only
if grep -A 30 'else if (outLayerType == "Region")' samples/dnn/object_detection.cpp | grep -B 5 'NMSBoxes' | grep -q '^    }$'; then
    echo "FAIL: object_detection.cpp should not have NMS inside Region block only" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: object_detection.cpp has NMS outside Region block"
    checks_passed=$((checks_passed + 1))
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
