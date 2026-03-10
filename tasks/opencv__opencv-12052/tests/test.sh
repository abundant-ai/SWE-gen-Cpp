#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12052: Support Inference Engine backend for Faster-RCNN, R-FCN, and Torch networks

# Check 1: Layer::forward should provide default implementation (not pure virtual)
if grep -q 'virtual void forward(InputArrayOfArrays inputs, OutputArrayOfArrays outputs, OutputArrayOfArrays internals);' modules/dnn/include/opencv2/dnn/dnn.hpp 2>/dev/null; then
    echo "PASS: Layer::forward has default implementation (not pure virtual)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Layer::forward should have default implementation, not be pure virtual" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Layer::forward default implementation should exist in dnn.cpp
if grep -q 'void Layer::forward(InputArrayOfArrays inputs, OutputArrayOfArrays outputs, OutputArrayOfArrays internals)' modules/dnn/src/dnn.cpp 2>/dev/null; then
    echo "PASS: Layer::forward default implementation exists in dnn.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Layer::forward default implementation should exist in dnn.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: DetectionOutput supportBackend should check _bboxesNormalized
if grep -A 4 'virtual bool supportBackend' modules/dnn/src/layers/detection_output_layer.cpp | grep -q '_bboxesNormalized'; then
    echo "PASS: DetectionOutput supports IE backend with _bboxesNormalized check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DetectionOutput should support IE backend with _bboxesNormalized check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: DetectionOutput forward should check _bboxesNormalized before OCL_RUN
if grep -B 5 'forward_ocl(inputs_arr, outputs_arr, internals_arr)' modules/dnn/src/layers/detection_output_layer.cpp | grep -q 'if (_bboxesNormalized)'; then
    echo "PASS: DetectionOutput forward checks _bboxesNormalized for OpenCL"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DetectionOutput forward should check _bboxesNormalized before OpenCL execution" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: PoolingLayerImpl supportBackend should have IE backend check with detailed logic
if grep -A 10 'virtual bool supportBackend' modules/dnn/src/layers/pooling_layer.cpp | grep -q 'if (backendId == DNN_BACKEND_INFERENCE_ENGINE)'; then
    echo "PASS: Pooling layer has detailed IE backend support check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Pooling layer should have detailed IE backend check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Pooling forward should check pool type before OCL_RUN
if grep -B 3 'forward_ocl(inputs_arr, outputs_arr, internals_arr)' modules/dnn/src/layers/pooling_layer.cpp | grep -q 'if (type == MAX || type == AVE || type == STOCHASTIC)'; then
    echo "PASS: Pooling forward checks type before OpenCL execution"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Pooling forward should check type before OpenCL execution" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: ProposalLayerImpl should support IE backend
if grep -A 5 'virtual bool supportBackend' modules/dnn/src/layers/proposal_layer.cpp | grep -q 'DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: Proposal layer supports IE backend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Proposal layer should support IE backend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: ProposalLayerImpl should have initInfEngine method
if grep -q 'virtual Ptr<BackendNode> initInfEngine' modules/dnn/src/layers/proposal_layer.cpp 2>/dev/null; then
    echo "PASS: Proposal layer has initInfEngine method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Proposal layer should have initInfEngine method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: ProposalLayerImpl should have full member variables
if grep -q 'uint32_t keepTopBeforeNMS' modules/dnn/src/layers/proposal_layer.cpp 2>/dev/null; then
    echo "PASS: Proposal layer has full member variables"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Proposal layer should have full member variables" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: OCL kernel should use Dtype parameter
if grep -q 'Dtype=%s.*KERNEL_STO_POOL' modules/dnn/src/ocl4dnn/src/ocl4dnn_pool.cpp 2>/dev/null; then
    echo "PASS: ocl4dnn_pool has Dtype parameter in kernel format"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocl4dnn_pool should have Dtype parameter in kernel format" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: OpenCL pooling kernel should use plain const pointer (not double const)
if grep -q '__global const Dtype\* bottom_data' modules/dnn/src/opencl/ocl4dnn_pooling.cl 2>/dev/null && \
   ! grep -q '__global const Dtype\* const bottom_data' modules/dnn/src/opencl/ocl4dnn_pooling.cl 2>/dev/null; then
    echo "PASS: OpenCL pooling kernel uses plain const pointer"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCL pooling kernel should use plain const pointer (not double const)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: Torch importer should have SpatialUpSamplingNearest handling
if grep -q 'SpatialUpSamplingNearest' modules/dnn/src/torch/torch_importer.cpp 2>/dev/null; then
    echo "PASS: Torch importer has SpatialUpSamplingNearest handling"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Torch importer should have SpatialUpSamplingNearest handling" >&2
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
