#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12082: TensorFlow Faster-RCNN Inception v2 support for Inference Engine backend

# Check 1: perf_net.cpp should have Inception_v2_Faster_RCNN test
if grep -q "PERF_TEST_P_(DNNTestNetwork, Inception_v2_Faster_RCNN)" modules/dnn/perf/perf_net.cpp 2>/dev/null; then
    echo "PASS: perf_net.cpp has Inception_v2_Faster_RCNN test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_net.cpp should have Inception_v2_Faster_RCNN test" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Inception_v2_Faster_RCNN test should process faster_rcnn_inception_v2_coco model
if grep -q 'processNet("dnn/faster_rcnn_inception_v2_coco_2018_01_28.pb"' modules/dnn/perf/perf_net.cpp 2>/dev/null; then
    echo "PASS: Inception_v2_Faster_RCNN test processes faster_rcnn_inception_v2_coco model"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Inception_v2_Faster_RCNN test should process faster_rcnn_inception_v2_coco model" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp should check for fused layers before supportBackend check (line ~1410)
if grep -q 'if (!fused && !layer->supportBackend(preferableBackend))' modules/dnn/src/dnn.cpp 2>/dev/null; then
    echo "PASS: dnn.cpp checks for fused layers before supportBackend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should check for fused layers before supportBackend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn.cpp should have proper layer skip logic (line ~2052)
if grep -q 'if( !ld.skip )' modules/dnn/src/dnn.cpp 2>/dev/null; then
    echo "PASS: dnn.cpp has proper layer skip logic"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should have proper layer skip logic" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dnn.cpp should check backendNodes map before accessing
if grep -q 'std::map<int, Ptr<BackendNode> >::iterator it = ld.backendNodes.find(preferableBackend);' modules/dnn/src/dnn.cpp 2>/dev/null; then
    echo "PASS: dnn.cpp checks backendNodes map before accessing"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should check backendNodes map before accessing" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: dnn.cpp should have proper backend node validation
if grep -q 'if (preferableBackend == DNN_BACKEND_OPENCV || it == ld.backendNodes.end() || it->second.empty())' modules/dnn/src/dnn.cpp 2>/dev/null; then
    echo "PASS: dnn.cpp has proper backend node validation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should have proper backend node validation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: detection_output_layer.cpp should check _clip in supportBackend
if grep -q 'backendId == DNN_BACKEND_INFERENCE_ENGINE && !_locPredTransposed && _bboxesNormalized && !_clip;' modules/dnn/src/layers/detection_output_layer.cpp 2>/dev/null; then
    echo "PASS: detection_output_layer.cpp checks _clip in supportBackend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should check _clip in supportBackend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: scale_layer.cpp should check axis == 1 for Inference Engine
if grep -q 'backendId == DNN_BACKEND_INFERENCE_ENGINE && axis == 1;' modules/dnn/src/layers/scale_layer.cpp 2>/dev/null; then
    echo "PASS: scale_layer.cpp checks axis == 1 for Inference Engine"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: scale_layer.cpp should check axis == 1 for Inference Engine" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: slice_layer.cpp should check sliceRanges[0].size() == 4 for Inference Engine
if grep -q 'backendId == DNN_BACKEND_INFERENCE_ENGINE && sliceRanges.size() == 1 && sliceRanges\[0\].size() == 4;' modules/dnn/src/layers/slice_layer.cpp 2>/dev/null; then
    echo "PASS: slice_layer.cpp checks sliceRanges[0].size() == 4 for Inference Engine"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: slice_layer.cpp should check sliceRanges[0].size() == 4 for Inference Engine" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: softmax_layer.cpp should use clamp for axis normalization
if grep -q 'ieLayer->axis = clamp(axisRaw, input->dims.size());' modules/dnn/src/layers/softmax_layer.cpp 2>/dev/null; then
    echo "PASS: softmax_layer.cpp uses clamp for axis normalization"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: softmax_layer.cpp should use clamp for axis normalization" >&2
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
