#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.cpp" "modules/dnn/test/test_common.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.hpp" "modules/dnn/test/test_common.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_darknet_importer.cpp" "modules/dnn/test/test_darknet_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13932 updates DNN test skip conditions for MyriadX/DLIE targets
# HEAD (6db3edd2e44fc3937b09ede8d7f274cd7cb47a31): New utility header and isMyriadX() function
# BASE (after bug.patch): Old version without utility header or isMyriadX()
# FIXED (after fix.patch): New utility header and isMyriadX() function (matches HEAD)

# Check 1: New utility header inference_engine.hpp should exist (fixed version)
if [ -f "modules/dnn/include/opencv2/dnn/utils/inference_engine.hpp" ]; then
    echo "PASS: inference_engine.hpp header exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: inference_engine.hpp header missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: getInferenceEngineVPUType function should be declared in inference_engine.hpp (fixed version)
if grep -q 'getInferenceEngineVPUType' modules/dnn/include/opencv2/dnn/utils/inference_engine.hpp 2>/dev/null; then
    echo "PASS: inference_engine.hpp declares getInferenceEngineVPUType (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: inference_engine.hpp missing getInferenceEngineVPUType declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: CV_DNN_INFERENCE_ENGINE_VPU_TYPE_MYRIAD_X constant should be defined (fixed version)
if grep -q 'CV_DNN_INFERENCE_ENGINE_VPU_TYPE_MYRIAD_X' modules/dnn/include/opencv2/dnn/utils/inference_engine.hpp 2>/dev/null; then
    echo "PASS: inference_engine.hpp defines MYRIAD_X constant (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: inference_engine.hpp missing MYRIAD_X constant (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: isMyriadX function should be declared in op_inf_engine.hpp (fixed version)
if grep -q 'bool isMyriadX' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp declares isMyriadX function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp missing isMyriadX declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: isMyriadX function should be implemented in op_inf_engine.cpp (fixed version)
if grep -q 'getInferenceEngineVPUType() == CV_DNN_INFERENCE_ENGINE_VPU_TYPE_MYRIAD_X' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp implements isMyriadX check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp missing isMyriadX implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: pooling_layer.cpp should use isMyriadX() for MyriadX-specific logic (fixed version)
if grep -q 'isMyriadX()' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "PASS: pooling_layer.cpp uses isMyriadX() function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pooling_layer.cpp missing isMyriadX() usage (buggy version)" >&2
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
