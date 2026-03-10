#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_darknet_importer.cpp" "modules/dnn/test/test_darknet_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11739: Enable FastNeuralStyle and OpenFace networks with IE backend

# Check 1: test_backends.cpp - OpenFace should have explicit OPENCL_FP16 skip
if grep -A 5 'TEST_P(DNNTestNetwork, OpenFace)' modules/dnn/test/test_backends.cpp | grep -q 'DNN_TARGET_OPENCL_FP16'; then
    echo "PASS: OpenFace test explicitly skips DNN_TARGET_OPENCL_FP16"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenFace test should explicitly skip DNN_TARGET_OPENCL_FP16" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: test_backends.cpp - OpenFace should have explicit MYRIAD skip
if grep -A 5 'TEST_P(DNNTestNetwork, OpenFace)' modules/dnn/test/test_backends.cpp | grep -q 'DNN_TARGET_MYRIAD'; then
    echo "PASS: OpenFace test explicitly skips DNN_TARGET_MYRIAD"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenFace test should explicitly skip DNN_TARGET_MYRIAD" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_backends.cpp - OpenFace should NOT use simplified skip logic
if ! grep -A 5 'TEST_P(DNNTestNetwork, OpenFace)' modules/dnn/test/test_backends.cpp | grep -q 'target != DNN_TARGET_CPU'; then
    echo "PASS: OpenFace test does not use simplified skip logic"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenFace test should not use simplified skip logic" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_backends.cpp - FastNeuralStyle_eccv16 test should exist
if grep -q 'TEST_P(DNNTestNetwork, FastNeuralStyle_eccv16)' modules/dnn/test/test_backends.cpp; then
    echo "PASS: FastNeuralStyle_eccv16 test exists in test_backends.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FastNeuralStyle_eccv16 test should exist in test_backends.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_darknet_importer.cpp - YoloVoc should NOT skip INFERENCE_ENGINE + MYRIAD
if ! grep -A 6 'TEST_P(Test_Darknet_nets, YoloVoc)' modules/dnn/test/test_darknet_importer.cpp | grep -q 'if (backendId == DNN_BACKEND_INFERENCE_ENGINE && targetId == DNN_TARGET_MYRIAD)'; then
    echo "PASS: YoloVoc test does not skip INFERENCE_ENGINE + MYRIAD"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: YoloVoc test should not skip INFERENCE_ENGINE + MYRIAD" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_torch_importer.cpp - FastNeuralStyle SHOULD force OPENCV backend after setInput
if grep -A 20 'TEST_P(Test_Torch_nets, FastNeuralStyle_accuracy)' modules/dnn/test/test_torch_importer.cpp | grep -A 5 'net.setInput(inputBlob)' | grep -q 'net.setPreferableBackend(DNN_BACKEND_OPENCV)'; then
    echo "PASS: FastNeuralStyle test forces OPENCV backend after setInput"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FastNeuralStyle test should force OPENCV backend after setInput" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: convolution_layer.cpp - supportBackend SHOULD have MYRIAD-specific logic
if grep -A 10 'virtual bool supportBackend' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'preferableTarget != DNN_TARGET_MYRIAD'; then
    echo "PASS: Convolution layer supportBackend has MYRIAD-specific logic"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Convolution layer supportBackend should have MYRIAD-specific logic" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: convolution_layer.cpp - supportBackend checks INFERENCE_ENGINE
if grep -A 10 'virtual bool supportBackend' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: Convolution layer supportBackend checks DNN_BACKEND_INFERENCE_ENGINE"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Convolution layer supportBackend should check DNN_BACKEND_INFERENCE_ENGINE" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: elementwise_layers.cpp - ElementWiseLayer supportBackend calls func.supportBackend()
if grep -A 60 'class ElementWiseLayer' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'func.supportBackend'; then
    echo "PASS: ElementWiseLayer supportBackend calls func.supportBackend()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ElementWiseLayer supportBackend should call func.supportBackend()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: elementwise_layers.cpp - ReLUFunctor supportBackend is present
if grep -A 15 'struct ReLUFunctor' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'bool supportBackend'; then
    echo "PASS: ReLUFunctor supportBackend method is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ReLUFunctor supportBackend method should be present" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: elementwise_layers.cpp - TanHFunctor supportBackend is present
if grep -A 15 'struct TanHFunctor' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'bool supportBackend'; then
    echo "PASS: TanHFunctor supportBackend method is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: TanHFunctor supportBackend method should be present" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: elementwise_layers.cpp - SigmoidFunctor supportBackend is present
if grep -A 15 'struct SigmoidFunctor' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'bool supportBackend'; then
    echo "PASS: SigmoidFunctor supportBackend method is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SigmoidFunctor supportBackend method should be present" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: elementwise_layers.cpp - PowerFunctor supportBackend is present
if grep -A 20 'struct PowerFunctor' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'bool supportBackend'; then
    echo "PASS: PowerFunctor supportBackend method is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PowerFunctor supportBackend method should be present" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: resize_layer.cpp - supportBackend SHOULD have MYRIAD-specific logic
if grep -A 10 'virtual bool supportBackend' modules/dnn/src/layers/resize_layer.cpp | grep -q 'preferableTarget != DNN_TARGET_MYRIAD'; then
    echo "PASS: Resize layer supportBackend has MYRIAD-specific logic"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Resize layer supportBackend should have MYRIAD-specific logic" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: resize_layer.cpp - supportBackend checks INFERENCE_ENGINE
if grep -A 10 'virtual bool supportBackend' modules/dnn/src/layers/resize_layer.cpp | grep -q 'DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: Resize layer supportBackend checks DNN_BACKEND_INFERENCE_ENGINE"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Resize layer supportBackend should check DNN_BACKEND_INFERENCE_ENGINE" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: slice_layer.cpp - supportBackend method is present
if grep -A 60 'class SliceLayerImpl' modules/dnn/src/layers/slice_layer.cpp | grep -q 'virtual bool supportBackend'; then
    echo "PASS: SliceLayer supportBackend method is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SliceLayer supportBackend method should be present" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: slice_layer.cpp - initInfEngine method is present
if grep -A 210 'class SliceLayerImpl' modules/dnn/src/layers/slice_layer.cpp | grep -q 'virtual Ptr<BackendNode> initInfEngine'; then
    echo "PASS: SliceLayer initInfEngine method is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SliceLayer initInfEngine method should be present" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: slice_layer.cpp - should include op_inf_engine.hpp
if grep -q '#include.*op_inf_engine.hpp' modules/dnn/src/layers/slice_layer.cpp; then
    echo "PASS: slice_layer.cpp includes op_inf_engine.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: slice_layer.cpp should include op_inf_engine.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: perf_net.cpp - OpenFace should have explicit MYRIAD skip
if grep -A 5 'PERF_TEST_P_(DNNTestNetwork, OpenFace)' modules/dnn/perf/perf_net.cpp | grep -q 'DNN_TARGET_MYRIAD'; then
    echo "PASS: Perf OpenFace test explicitly skips DNN_TARGET_MYRIAD"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Perf OpenFace test should explicitly skip DNN_TARGET_MYRIAD" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 19: perf_net.cpp - FastNeuralStyle_eccv16 test exists
if grep -q 'PERF_TEST_P_(DNNTestNetwork, FastNeuralStyle_eccv16)' modules/dnn/perf/perf_net.cpp; then
    echo "PASS: FastNeuralStyle_eccv16 perf test exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FastNeuralStyle_eccv16 perf test should exist" >&2
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
