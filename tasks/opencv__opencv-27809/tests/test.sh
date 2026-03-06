#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

# Check if the NegativeLogLikelihoodLossLayer and SoftmaxCrossEntropyLossLayer classes exist in the header file
# In BASE state (buggy), these classes are removed
# In HEAD state (fixed), the classes are present
checks_passed=0
checks_failed=0

if grep -q 'class CV_EXPORTS NegativeLogLikelihoodLossLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: NegativeLogLikelihoodLossLayer class present in header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NegativeLogLikelihoodLossLayer class missing from header (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

if grep -q 'class CV_EXPORTS SoftmaxCrossEntropyLossLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: SoftmaxCrossEntropyLossLayer class present in header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SoftmaxCrossEntropyLossLayer class missing from header (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that test entries were removed from the denylist (they should not be present in HEAD)
if ! grep -q '"test_nllloss_NCd1_mean_weight_negative_ii",' modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp; then
    echo "PASS: test_nllloss_NCd1_mean_weight_negative_ii removed from denylist (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_nllloss_NCd1_mean_weight_negative_ii still in denylist (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

if ! grep -q '"test_sce_mean",' modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp; then
    echo "PASS: test_sce_mean removed from denylist (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_sce_mean still in denylist (buggy version)" >&2
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
