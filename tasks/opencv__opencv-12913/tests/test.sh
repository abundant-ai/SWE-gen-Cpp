#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_darknet_importer.cpp" "modules/dnn/test/test_darknet_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12913: Add support for extra hyperparameters in Inference Engine backend
# For harbor testing:
# - HEAD (b5c54e447cd8ca59a289cc99a9af33e7425a026f): Fixed version with hyperparameters support
# - BASE (after bug.patch): Buggy version with hyperparameters removed
# - FIXED (after fix.patch): Back to fixed version

# Check 1: INF_ENGINE_RELEASE should be 2018R4 (2018040000) in fixed version
if grep -q 'set(INF_ENGINE_RELEASE "2018040000"' cmake/OpenCVDetectInferenceEngine.cmake; then
    echo "PASS: INF_ENGINE_RELEASE is 2018040000 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: INF_ENGINE_RELEASE is not 2018040000 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.cpp should have versionTrigger for hyperparameters version specification
if grep -q 'std::string versionTrigger.*TestInput.*version.*3' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp has versionTrigger for hyperparameters version - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing versionTrigger - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: blank_layer.cpp should set axis param
if grep -q 'ieLayer->params\["axis"\]' modules/dnn/src/layers/blank_layer.cpp; then
    echo "PASS: blank_layer.cpp sets axis param - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blank_layer.cpp missing axis param - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: blank_layer.cpp should set out_sizes param
if grep -q 'ieLayer->params\["out_sizes"\]' modules/dnn/src/layers/blank_layer.cpp; then
    echo "PASS: blank_layer.cpp sets out_sizes param - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blank_layer.cpp missing out_sizes param - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: convolution_layer.cpp should set output param
if grep -q 'ieLayer->params\["output"\]' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp sets output param - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp missing output param - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: convolution_layer.cpp should set kernel param
if grep -q 'ieLayer->params\["kernel"\]' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp sets kernel param - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp missing kernel param - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: convolution_layer.cpp should set pads_begin param
if grep -q 'ieLayer->params\["pads_begin"\]' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp sets pads_begin param - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp missing pads_begin param - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: convolution_layer.cpp should set strides param
if grep -q 'ieLayer->params\["strides"\]' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp sets strides param - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp missing strides param - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: convolution_layer.cpp should set dilations param
if grep -q 'ieLayer->params\["dilations"\]' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp sets dilations param - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp missing dilations param - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: crop_layer.cpp should have axis push_back in loop
if grep -q 'ieLayer->axis.push_back' modules/dnn/src/layers/crop_layer.cpp; then
    echo "PASS: crop_layer.cpp has axis push_back - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: crop_layer.cpp missing axis push_back - buggy version" >&2
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
