#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13774 fixes DNN backend support conditions
# HEAD (183c0fcab199b32774d1e4f1261f8b3a4d12777f): Fixed version with proper backend support checks
# BASE (after bug.patch): Buggy version with incorrect backend support conditions
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: perf_net.cpp should NOT have DNN_TARGET_OPENCL_FP16 skip condition (fixed version)
if grep -q 'backend == DNN_BACKEND_INFERENCE_ENGINE && target == DNN_TARGET_OPENCL_FP16' modules/dnn/perf/perf_net.cpp; then
    echo "FAIL: perf_net.cpp has DNN_TARGET_OPENCL_FP16 skip condition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: perf_net.cpp does not have DNN_TARGET_OPENCL_FP16 skip condition (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 2: lrn_layer.cpp should have simple backend check without Myriad condition (fixed version)
if grep -q 'backendId == DNN_BACKEND_INFERENCE_ENGINE && (preferableTarget != DNN_TARGET_MYRIAD || type == CHANNEL_NRM)' modules/dnn/src/layers/lrn_layer.cpp; then
    echo "FAIL: lrn_layer.cpp has Myriad condition in backend check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: lrn_layer.cpp has simple backend check (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: normalize_bbox_layer.cpp should NOT have the buggy multi-line condition after pnorm check (fixed version)
# The buggy version has: if (!blobs.empty()) return true; after the pnorm check
# The fixed version has: return preferableTarget == ... directly after pnorm check
if grep -A 3 'if (pnorm != 2)' modules/dnn/src/layers/normalize_bbox_layer.cpp | grep -q 'if (!blobs.empty())'; then
    echo "FAIL: normalize_bbox_layer.cpp has blob check after pnorm check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: normalize_bbox_layer.cpp does not have blob check after pnorm check (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: normalize_bbox_layer.cpp should have simple ternary return (fixed version)
if grep -q 'return preferableTarget == DNN_TARGET_MYRIAD ? !acrossSpatial : startAxis == 1;' modules/dnn/src/layers/normalize_bbox_layer.cpp; then
    echo "PASS: normalize_bbox_layer.cpp has simple ternary return (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp does not have simple ternary return (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: resize_layer.cpp should have 'scaleWidth == scaleHeight' condition (fixed version)
if grep -q 'interpolation == "nearest" && scaleWidth == scaleHeight' modules/dnn/src/layers/resize_layer.cpp; then
    echo "PASS: resize_layer.cpp has scaleWidth == scaleHeight condition (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize_layer.cpp does not have scaleWidth == scaleHeight condition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: resize_layer.cpp should NOT have Myriad target check in nearest interpolation (fixed version)
if grep -q 'interpolation == "nearest" && preferableTarget != DNN_TARGET_MYRIAD' modules/dnn/src/layers/resize_layer.cpp; then
    echo "FAIL: resize_layer.cpp has Myriad target check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: resize_layer.cpp does not have Myriad target check (fixed version)"
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
