#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_darknet_importer.cpp" "modules/dnn/test/test_darknet_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_precomp.hpp" "modules/dnn/test/test_precomp.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #11867: Fix DNN backend/target support for multiple layer types

# Check 1: dnn.cpp - c_split should be declared inside the if (outW == 1 && outH == 1) block
if grep -A 2 'if (outW == 1 && outH == 1)' modules/dnn/src/dnn.cpp | grep -q 'int c_split = outC > 8'; then
    echo "PASS: c_split is properly scoped inside outW==1 && outH==1 block"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: c_split should be declared inside the if (outW == 1 && outH == 1) block" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.cpp - c_split with std::min should exist in the else block with comment
if grep -B 1 'int c_split = outC > 8 ? (outC > 16 ? 8 : 4) : std::min(4, outC);' modules/dnn/src/dnn.cpp | grep -q 'Supported vectorization widths'; then
    echo "PASS: c_split with std::min and comment exists in else block"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: c_split with std::min and comment should be in else block" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: convolution_layer.cpp - supportBackend should have detailed logic for INFERENCE_ENGINE
if grep -A 15 'if (backendId == DNN_BACKEND_INFERENCE_ENGINE)' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'if (type == "Convolution")' && \
   grep -A 15 'if (backendId == DNN_BACKEND_INFERENCE_ENGINE)' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'CV_Assert(type == "Deconvolution")'; then
    echo "PASS: convolution_layer.cpp has detailed supportBackend logic for Convolution and Deconvolution"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp should have separate logic for Convolution and Deconvolution types" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: convolution_layer.cpp - should check group and dilation for Deconvolution
if grep -A 15 'CV_Assert(type == "Deconvolution")' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'const int outGroupCn = blobs\[0\].size\[1\]' && \
   grep -A 15 'CV_Assert(type == "Deconvolution")' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'if (group != 1)'; then
    echo "PASS: Deconvolution support checks group and dilation properly"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Deconvolution should check group and dilation settings" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: eltwise_layer.cpp - supportBackend should have simple HALIDE check without haveHalide()
if grep -A 3 'virtual bool supportBackend' modules/dnn/src/layers/eltwise_layer.cpp | grep -q 'backendId == DNN_BACKEND_HALIDE ||' && \
   ! grep -A 3 'virtual bool supportBackend' modules/dnn/src/layers/eltwise_layer.cpp | grep -q 'haveHalide()'; then
    echo "PASS: eltwise_layer.cpp supportBackend does not use haveHalide() check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: eltwise_layer.cpp should not check haveHalide() in supportBackend" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: eltwise_layer.cpp - should check op and coeffs for INFERENCE_ENGINE
if grep -A 5 'virtual bool supportBackend' modules/dnn/src/layers/eltwise_layer.cpp | grep -F 'op != SUM' | grep -q 'coeffs.empty()'; then
    echo "PASS: eltwise_layer.cpp checks op and coeffs for INFERENCE_ENGINE backend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: eltwise_layer.cpp should check (op != SUM || coeffs.empty()) for INFERENCE_ENGINE" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: reorg_layer.cpp - should include op_inf_engine.hpp
if grep -q '#include "../op_inf_engine.hpp"' modules/dnn/src/layers/reorg_layer.cpp; then
    echo "PASS: reorg_layer.cpp includes op_inf_engine.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp should include op_inf_engine.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: reorg_layer.cpp - should NOT include iostream
if ! grep -q '#include <iostream>' modules/dnn/src/layers/reorg_layer.cpp; then
    echo "PASS: reorg_layer.cpp does not include iostream"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp should not include iostream" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: reorg_layer.cpp - should have supportBackend method
if grep -q 'virtual bool supportBackend(int backendId) CV_OVERRIDE' modules/dnn/src/layers/reorg_layer.cpp; then
    echo "PASS: reorg_layer.cpp has supportBackend method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp should have supportBackend method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: reorg_layer.cpp - should support OPENCV and INFERENCE_ENGINE backends
if grep -A 3 'virtual bool supportBackend' modules/dnn/src/layers/reorg_layer.cpp | grep -q 'backendId == DNN_BACKEND_OPENCV || backendId == DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: reorg_layer.cpp supports OPENCV and INFERENCE_ENGINE backends"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp should support OPENCV and INFERENCE_ENGINE backends" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: reorg_layer.cpp - should have initInfEngine method
if grep -q 'virtual Ptr<BackendNode> initInfEngine(const std::vector<Ptr<BackendWrapper> >&) CV_OVERRIDE' modules/dnn/src/layers/reorg_layer.cpp; then
    echo "PASS: reorg_layer.cpp has initInfEngine method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp should have initInfEngine method" >&2
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
