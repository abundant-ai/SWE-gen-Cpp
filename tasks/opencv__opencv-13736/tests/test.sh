#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13736 fixes OpenVINO/Inference Engine backend compatibility for newer versions
# HEAD (c918ac298c16eab75abd4e3dc46cc47dbb4c8fa6): Fixed version with proper version checks and Myriad target handling
# BASE (after bug.patch): Buggy version with overly strict version checks
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: blank_layer.cpp should have conditional Myriad handling in initInfEngine (fixed version)
if grep -q 'if (preferableTarget == DNN_TARGET_MYRIAD)' modules/dnn/src/layers/blank_layer.cpp; then
    echo "PASS: blank_layer.cpp has Myriad target conditional (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blank_layer.cpp missing Myriad target conditional (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: blank_layer.cpp should set Copy type for Myriad (fixed version)
if grep -q 'ieLayer.setType("Copy");' modules/dnn/src/layers/blank_layer.cpp; then
    echo "PASS: blank_layer.cpp sets Copy type for Myriad (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blank_layer.cpp missing Copy type for Myriad (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: blank_layer.cpp should have InferenceEngine::Builder::Layer with parameters (fixed version)
if grep -q 'getParameters().*axis.*input->dims.size()' modules/dnn/src/layers/blank_layer.cpp; then
    echo "PASS: blank_layer.cpp has axis parameter setup (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blank_layer.cpp missing axis parameter setup (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: convolution_layer.cpp should use >= comparison for INF_ENGINE_RELEASE (fixed version)
if grep -q 'if (INF_ENGINE_RELEASE >= 2018050000 && (adjustPad.height || adjustPad.width))' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp uses >= for version check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp uses == for version check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_layers.cpp should have Myriad skip condition (fixed version)
if grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE > 2018050000' modules/dnn/test/test_layers.cpp && \
   grep -q 'if (backend == DNN_BACKEND_INFERENCE_ENGINE && target == DNN_TARGET_MYRIAD)' modules/dnn/test/test_layers.cpp; then
    echo "PASS: test_layers.cpp has Myriad skip condition (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp missing Myriad skip condition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_onnx_importer.cpp should use >= comparison for version check (fixed version)
if grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE >= 2018050000' modules/dnn/test/test_onnx_importer.cpp; then
    echo "PASS: test_onnx_importer.cpp uses >= for version check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp uses == for version check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_tf_importer.cpp should use >= comparison in leaky_relu test (fixed version)
if grep -A 2 'TEST_P(Test_TensorFlow_layers, leaky_relu)' modules/dnn/test/test_tf_importer.cpp | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE >= 2018050000'; then
    echo "PASS: test_tf_importer.cpp uses >= in leaky_relu test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp uses == in leaky_relu test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_tf_importer.cpp should use >= comparison in MobileNet_v1_SSD_PPN test (fixed version)
if grep -A 2 'TEST_P(Test_TensorFlow_nets, MobileNet_v1_SSD_PPN)' modules/dnn/test/test_tf_importer.cpp | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE >= 2018050000'; then
    echo "PASS: test_tf_importer.cpp uses >= in MobileNet_v1_SSD_PPN test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp uses == in MobileNet_v1_SSD_PPN test (buggy version)" >&2
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
