#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12243: Fix TensorFlow Mask R-CNN graph importer
# The fix adds support for importing Mask R-CNN graphs from TensorFlow
# For harbor testing:
# - HEAD (c53b7f8443ce3eb6b5386889aeea9e5f7ab1f6da): Fixed version with Mask_RCNN test and supporting code
# - BASE (after bug.patch): Buggy version without Mask_RCNN test
# - FIXED (after oracle applies fix): Back to fixed version

# Check 1: test_tf_importer.cpp should have Mask_RCNN test (fixed version)
if grep -q 'TEST(Test_TensorFlow, Mask_RCNN)' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp has Mask_RCNN test - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should have Mask_RCNN test - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Test should include readNetFromTensorflow call (fixed version)
if grep -q 'Net net = readNetFromTensorflow(model, proto);' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp has readNetFromTensorflow call - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should have readNetFromTensorflow call - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Test should include mask_rcnn model reference (fixed version)
if grep -q 'mask_rcnn_inception_v2_coco_2018_01_28' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp references Mask R-CNN model - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should reference Mask R-CNN model - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Test should include detection_masks output (fixed version)
if grep -q 'detection_masks' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp includes detection_masks output - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should include detection_masks output - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: crop_and_resize_layer.cpp should handle boxes.rows < out.size[0] (fixed version)
if grep -q 'if (boxes.rows < out.size\[0\])' modules/dnn/src/layers/crop_and_resize_layer.cpp; then
    echo "PASS: crop_and_resize_layer.cpp handles boxes.rows < out.size[0] - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: crop_and_resize_layer.cpp should handle boxes.rows < out.size[0] - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: detection_output_layer.cpp should have _groupByClasses member (fixed version)
if grep -q 'bool _groupByClasses;' modules/dnn/src/layers/detection_output_layer.cpp; then
    echo "PASS: detection_output_layer.cpp has _groupByClasses member - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should have _groupByClasses member - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: detection_output_layer.cpp should read group_by_classes parameter (fixed version)
if grep -q '_groupByClasses = getParameter<bool>(params, "group_by_classes"' modules/dnn/src/layers/detection_output_layer.cpp; then
    echo "PASS: detection_output_layer.cpp reads group_by_classes parameter - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should read group_by_classes parameter - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: detection_output_layer.cpp should pass groupByClasses to outputDetections_ (fixed version)
if grep -q 'allIndices\[i\], _groupByClasses);' modules/dnn/src/layers/detection_output_layer.cpp; then
    echo "PASS: detection_output_layer.cpp passes _groupByClasses to outputDetections_ - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: detection_output_layer.cpp should pass _groupByClasses to outputDetections_ - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: tf_importer.cpp should handle Const nodes properly (fixed version - check for const blob handling)
if grep -q 'getConstBlob' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp has getConstBlob function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should have getConstBlob function - buggy version" >&2
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
