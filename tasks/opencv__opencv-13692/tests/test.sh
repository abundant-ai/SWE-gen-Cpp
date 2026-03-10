#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #13692 removes ASSERT_ANY_THROW checks for Myriad plugin with FP32 networks
# and adds proper size_t casts to fix type conversion warnings in Inference Engine code.
# HEAD (ff775b2e54a8f1e6be2866a783f384224dc509dd): Fixed version with size_t casts
# BASE (after bug.patch): Buggy version without proper casts
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: convolution_layer.cpp should have size_t casts for setKernel in ConvolutionLayer
if grep -q 'ieLayer\.setKernel({(size_t)kernel\.height, (size_t)kernel\.width})' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp has size_t casts for setKernel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp does not have size_t casts for setKernel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: convolution_layer.cpp should have size_t casts for setStrides in ConvolutionLayer
if grep -q 'ieLayer\.setStrides({(size_t)stride\.height, (size_t)stride\.width})' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp has size_t casts for setStrides (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp does not have size_t casts for setStrides (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: convolution_layer.cpp should have size_t casts for setGroup in ConvolutionLayer
if grep -q 'ieLayer\.setGroup((size_t)group)' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp has size_t casts for setGroup (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp does not have size_t casts for setGroup (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: convolution_layer.cpp should have size_t casts for setOutDepth in ConvolutionLayer
if grep -q 'ieLayer\.setOutDepth((size_t)outCn)' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp has size_t casts for setOutDepth (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp does not have size_t casts for setOutDepth (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: convolution_layer.cpp should have size_t casts in DeconvolutionLayer
if grep -q 'ieLayer\.setOutDepth((size_t)numOutput)' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp has size_t casts for DeconvolutionLayer setOutDepth (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp does not have size_t casts for DeconvolutionLayer setOutDepth (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: pooling_layer.cpp should have size_t casts for setKernel
if grep -q 'ieLayer\.setKernel({(size_t)kernel\.height, (size_t)kernel\.width})' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "PASS: pooling_layer.cpp has size_t casts for setKernel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pooling_layer.cpp does not have size_t casts for setKernel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: pooling_layer.cpp should have size_t casts for setPaddingsBegin
if grep -q 'ieLayer\.setPaddingsBegin({(size_t)pad_t, (size_t)pad_l})' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "PASS: pooling_layer.cpp has size_t casts for setPaddingsBegin (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pooling_layer.cpp does not have size_t casts for setPaddingsBegin (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: op_inf_engine.cpp should have size_t in loop variable
if grep -q 'for (size_t i = 0; i < inpWrappers\.size(); ++i)' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp has size_t loop variable (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp does not have size_t loop variable (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: op_inf_engine.cpp should have size_t casts in netBuilder.connect
if grep -q 'netBuilder\.connect((size_t)inpId, {(size_t)layerId, i})' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp has size_t casts in netBuilder.connect (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp does not have size_t casts in netBuilder.connect (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: op_inf_engine.cpp should have PortInfo cast in addLayer
if grep -q 'netBuilder\.addLayer({InferenceEngine::PortInfo(id)}, outLayer)' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp has PortInfo cast in addLayer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp does not have PortInfo cast in addLayer (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: dnn.cpp should have proper convolution setup (not Identity layer)
if grep -q 'lp\.set("kernel_size", 1)' modules/dnn/src/dnn.cpp && \
   grep -q 'lp\.type = "Convolution"' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp has proper convolution layer setup (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp does not have proper convolution layer setup (buggy version)" >&2
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
