#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12350: Fix Faster-RCNN Caffe models import for OpenCL FP16
# For harbor testing:
# - HEAD (ea43e28a37836dd5e630f471f25f425bb65ecca0): Fixed version with proper backend support and FP16 handling
# - BASE (after bug.patch): Buggy version without proper backend support
# - FIXED (after oracle applies fix): Back to fixed version with all fixes
#
# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: crop_layer.cpp should include op_inf_engine.hpp (fixed version)
if grep -q '#include "../op_inf_engine.hpp"' modules/dnn/src/layers/crop_layer.cpp; then
    echo "PASS: crop_layer.cpp includes op_inf_engine.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: crop_layer.cpp should include op_inf_engine.hpp - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: crop_layer.cpp should have supportBackend method (fixed version)
if grep -q 'virtual bool supportBackend(int backendId) CV_OVERRIDE' modules/dnn/src/layers/crop_layer.cpp; then
    echo "PASS: crop_layer.cpp has supportBackend method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: crop_layer.cpp should have supportBackend method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: crop_layer.cpp should have explicit crop_ranges initialization loop (fixed version)
if grep -q 'for (int i = 0; i < start_axis; i++)' modules/dnn/src/layers/crop_layer.cpp && \
   grep -q 'crop_ranges\[i\] = Range(0, inpBlob.size\[i\]);' modules/dnn/src/layers/crop_layer.cpp; then
    echo "PASS: crop_layer.cpp has explicit crop_ranges initialization - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: crop_layer.cpp should have explicit crop_ranges initialization - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: crop_layer.cpp should have initInfEngine method (fixed version)
if grep -q 'virtual Ptr<BackendNode> initInfEngine' modules/dnn/src/layers/crop_layer.cpp; then
    echo "PASS: crop_layer.cpp has initInfEngine method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: crop_layer.cpp should have initInfEngine method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: fully_connected_layer.cpp should have FP16 conversion variables (fixed version)
if grep -q 'UMat srcMat, dstMat, srcMat_fp32, dstMat_fp32;' modules/dnn/src/layers/fully_connected_layer.cpp; then
    echo "PASS: fully_connected_layer.cpp has FP16 conversion variables - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: fully_connected_layer.cpp should have FP16 conversion variables - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: fully_connected_layer.cpp should have convertFp16 calls (fixed version)
if grep -q 'convertFp16(srcMat, srcMat_fp32);' modules/dnn/src/layers/fully_connected_layer.cpp && \
   grep -q 'convertFp16(dstMat, dstMat_fp32);' modules/dnn/src/layers/fully_connected_layer.cpp; then
    echo "PASS: fully_connected_layer.cpp has convertFp16 calls - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: fully_connected_layer.cpp should have convertFp16 calls - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: fully_connected_layer.cpp should use fp32 matrices in gemm (fixed version)
if grep -q 'cv::gemm(srcMat_fp32, weights, 1, noArray(), 0, dstMat_fp32, GEMM_2_T);' modules/dnn/src/layers/fully_connected_layer.cpp; then
    echo "PASS: fully_connected_layer.cpp uses fp32 matrices in gemm - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: fully_connected_layer.cpp should use fp32 matrices in gemm - buggy version" >&2
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
