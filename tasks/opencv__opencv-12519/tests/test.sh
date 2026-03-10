#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12519: Add asymmetric padding support to ONNX pooling operations
# For harbor testing:
# - HEAD (dbb8a891104c3da0974c639dd3ed9fbc1054a5f8): Fixed version with asymmetric padding
# - BASE (after bug.patch): Buggy version without asymmetric padding (symmetric only)
# - FIXED (after oracle applies fix): Back to fixed version with asymmetric padding

# Check 1: PoolingLayer struct SHOULD have separate pad_l, pad_t, pad_r, pad_b fields (fixed version)
if grep -q 'int pad_l, pad_t, pad_r, pad_b;' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: PoolingLayer has separate pad_l, pad_t, pad_r, pad_b fields - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PoolingLayer missing separate padding fields - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: getStrideAndPadding SHOULD accept separate padT, padL, padB, padR parameters (fixed version)
if grep -q 'void getStrideAndPadding(const LayerParams &params, int &padT, int &padL, int &padB, int &padR, int &strideH, int &strideW, cv::String& padMode)' modules/dnn/src/layers/layers_common.cpp; then
    echo "PASS: getStrideAndPadding accepts asymmetric padding parameters - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: getStrideAndPadding uses symmetric padding only - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: getStrideAndPadding SHOULD read pad_l, pad_t, pad_r, pad_b from params (fixed version)
if grep -q 'if (params.has("pad_l") && params.has("pad_t") && params.has("pad_r") && params.has("pad_b"))' modules/dnn/src/layers/layers_common.cpp; then
    echo "PASS: getStrideAndPadding reads asymmetric padding from params - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: getStrideAndPadding doesn't read asymmetric padding - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: getPoolingKernelParams SHOULD accept separate padding parameters (fixed version)
if grep -q 'void getPoolingKernelParams(const LayerParams &params, int &kernelH, int &kernelW, bool &globalPooling,' modules/dnn/src/layers/layers_common.cpp && \
   grep -q 'int &padT, int &padL, int &padB, int &padR, int &strideH, int &strideW, cv::String &padMode)' modules/dnn/src/layers/layers_common.cpp; then
    echo "PASS: getPoolingKernelParams accepts asymmetric padding - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: getPoolingKernelParams uses symmetric padding only - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: PoolingInvoker SHOULD have separate pad_l, pad_t, pad_r, pad_b fields (fixed version)
if grep -q 'int pad_l, pad_t, pad_r, pad_b;' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "PASS: PoolingInvoker has separate padding fields - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PoolingInvoker missing separate padding fields - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: PoolingInvoker::run SHOULD accept separate padding parameters (fixed version)
if grep -q 'Size stride, int pad_l, int pad_t, int pad_r, int pad_b, bool avePoolPaddedArea' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "PASS: PoolingInvoker::run accepts asymmetric padding - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PoolingInvoker::run uses symmetric padding only - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: OCL4DNNPoolConfig SHOULD have pad_l, pad_t, pad_r, pad_b fields (fixed version)
if grep -q 'int pad_l, pad_t, pad_r, pad_b;' modules/dnn/src/ocl4dnn/include/ocl4dnn.hpp; then
    echo "PASS: OCL4DNNPoolConfig has asymmetric padding fields - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OCL4DNNPoolConfig missing asymmetric padding fields - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: ONNX importer SHOULD set pad_t and pad_l (not pad_h and pad_w) (fixed version)
if grep -q 'lp.set("pad_t", saturate_cast<int32_t>(attribute_proto.ints(0)));' modules/dnn/src/onnx/onnx_importer.cpp && \
   grep -q 'lp.set("pad_l", saturate_cast<int32_t>(attribute_proto.ints(1)));' modules/dnn/src/onnx/onnx_importer.cpp; then
    echo "PASS: ONNX importer uses pad_t/pad_l for asymmetric padding - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ONNX importer doesn't use pad_t/pad_l - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: ONNX importer SHOULD set pad_b and pad_r (fixed version)
if grep -q 'lp.set("pad_b", saturate_cast<int32_t>(attribute_proto.ints(2)));' modules/dnn/src/onnx/onnx_importer.cpp && \
   grep -q 'lp.set("pad_r", saturate_cast<int32_t>(attribute_proto.ints(3)));' modules/dnn/src/onnx/onnx_importer.cpp; then
    echo "PASS: ONNX importer sets pad_b/pad_r - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ONNX importer doesn't set pad_b/pad_r - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: OpenCL kernel SHOULD use PAD_L, PAD_T, PAD_R, PAD_B defines (fixed version)
if grep -q 'PAD_L=%d -D PAD_T=%d -D PAD_R=%d -D PAD_B=%d' modules/dnn/src/ocl4dnn/src/ocl4dnn_pool.cpp; then
    echo "PASS: OpenCL kernel uses asymmetric padding defines - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCL kernel doesn't use asymmetric padding defines - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: OpenCL kernel source SHOULD use PAD_T and PAD_L (fixed version)
if grep -q 'int hstart = ph \* STRIDE_H - PAD_T;' modules/dnn/src/opencl/ocl4dnn_pooling.cl && \
   grep -q 'int wstart = pw \* STRIDE_W - PAD_L;' modules/dnn/src/opencl/ocl4dnn_pooling.cl; then
    echo "PASS: OpenCL kernel uses PAD_T and PAD_L - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCL kernel doesn't use PAD_T and PAD_L - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: OpenCL kernel source SHOULD use PAD_B and PAD_R for pooling end (fixed version)
if grep -q 'int hend = min(hstart + KERNEL_H, height + PAD_B);' modules/dnn/src/opencl/ocl4dnn_pooling.cl && \
   grep -q 'int wend = min(wstart + KERNEL_W, width + PAD_R);' modules/dnn/src/opencl/ocl4dnn_pooling.cl; then
    echo "PASS: OpenCL kernel uses PAD_B and PAD_R for end calculation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCL kernel doesn't use PAD_B and PAD_R - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: Pooling layer SHOULD use pad_t + pad_b for height calculation (fixed version)
if grep -q 'float height = (float)(in.height + pad_t + pad_b - kernel.height) / stride.height;' modules/dnn/src/layers/pooling_layer.cpp && \
   grep -q 'float width = (float)(in.width + pad_l + pad_r - kernel.width) / stride.width;' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "PASS: Pooling layer uses asymmetric padding in size calculation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Pooling layer doesn't use asymmetric padding in calculation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: Pooling layer SHOULD check pad_r and pad_b for clipping (fixed version)
if grep -q 'if (pad_r || pad_b)' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "PASS: Pooling layer checks pad_r and pad_b for clipping - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Pooling layer doesn't check pad_r and pad_b - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: Convolution layer SHOULD check for asymmetric padding and error (fixed version)
if grep -q 'if (pad_t != pad_b || pad_l != pad_r)' modules/dnn/src/layers/convolution_layer.cpp && \
   grep -q 'CV_Error(Error::StsNotImplemented, "Unsupported asymmetric padding in convolution layer");' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: Convolution layer detects and rejects asymmetric padding - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Convolution layer doesn't check for asymmetric padding - buggy version" >&2
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
