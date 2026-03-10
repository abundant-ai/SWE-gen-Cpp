#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #11791: Add ShuffleChannelLayer implementation to DNN module

# Check 1: all_layers.hpp - ShuffleChannelLayer class should be declared
if grep -q 'class CV_EXPORTS ShuffleChannelLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: ShuffleChannelLayer class is declared in all_layers.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayer class should be declared in all_layers.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: all_layers.hpp - ShuffleChannelLayer should have create method
if grep -A 5 'class CV_EXPORTS ShuffleChannelLayer' modules/dnn/include/opencv2/dnn/all_layers.hpp | grep -q 'static Ptr<Layer> create(const LayerParams& params)'; then
    echo "PASS: ShuffleChannelLayer has create method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayer should have static create method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: all_layers.hpp - ShuffleChannelLayer should have group member
if grep -A 7 'class CV_EXPORTS ShuffleChannelLayer' modules/dnn/include/opencv2/dnn/all_layers.hpp | grep -q 'int group'; then
    echo "PASS: ShuffleChannelLayer has group member variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayer should have int group member" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: all_layers.hpp - ShuffleChannelLayer should have documentation about permuting channels
if grep -B 8 'class CV_EXPORTS ShuffleChannelLayer' modules/dnn/include/opencv2/dnn/all_layers.hpp | grep -q 'Permute channels of 4-dimensional input blob'; then
    echo "PASS: ShuffleChannelLayer has documentation about permuting channels"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayer should have documentation mentioning permuting channels" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: init.cpp - ShuffleChannel layer should be registered
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(ShuffleChannel, ShuffleChannelLayer)' modules/dnn/src/init.cpp; then
    echo "PASS: ShuffleChannel layer is registered in init.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannel layer should be registered with CV_DNN_REGISTER_LAYER_CLASS" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: shuffle_channel_layer.cpp - File should exist
if [ -f "modules/dnn/src/layers/shuffle_channel_layer.cpp" ]; then
    echo "PASS: shuffle_channel_layer.cpp file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shuffle_channel_layer.cpp should exist in modules/dnn/src/layers/" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: shuffle_channel_layer.cpp - ShuffleChannelLayerImpl class should exist
if grep -q 'class ShuffleChannelLayerImpl CV_FINAL : public ShuffleChannelLayer' modules/dnn/src/layers/shuffle_channel_layer.cpp 2>/dev/null; then
    echo "PASS: ShuffleChannelLayerImpl class is implemented"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayerImpl should be implemented in shuffle_channel_layer.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: shuffle_channel_layer.cpp - Should have constructor that reads group parameter
if grep -A 3 'ShuffleChannelLayerImpl(const LayerParams& params)' modules/dnn/src/layers/shuffle_channel_layer.cpp 2>/dev/null | grep -q 'group = params.get<int>("group"'; then
    echo "PASS: Constructor reads group parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Constructor should read group parameter from LayerParams" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: shuffle_channel_layer.cpp - Should override getMemoryShapes
if grep -q 'bool getMemoryShapes' modules/dnn/src/layers/shuffle_channel_layer.cpp 2>/dev/null; then
    echo "PASS: ShuffleChannelLayerImpl overrides getMemoryShapes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayerImpl should override getMemoryShapes" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: shuffle_channel_layer.cpp - Should override finalize method
if grep -q 'virtual void finalize.*CV_OVERRIDE' modules/dnn/src/layers/shuffle_channel_layer.cpp 2>/dev/null; then
    echo "PASS: ShuffleChannelLayerImpl overrides finalize method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayerImpl should override finalize method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: shuffle_channel_layer.cpp - Should have forward implementation
if grep -q 'void forward' modules/dnn/src/layers/shuffle_channel_layer.cpp 2>/dev/null; then
    echo "PASS: ShuffleChannelLayerImpl has forward implementation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayerImpl should implement forward method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: shuffle_channel_layer.cpp - ShuffleChannelLayer::create factory method should exist
if grep -q 'Ptr<Layer> ShuffleChannelLayer::create(const LayerParams& params)' modules/dnn/src/layers/shuffle_channel_layer.cpp 2>/dev/null; then
    echo "PASS: ShuffleChannelLayer::create factory method exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ShuffleChannelLayer should have create factory method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: crop_and_resize_layer.cpp - Should have copyright header
if grep -q '// This file is part of OpenCV project' modules/dnn/src/layers/crop_and_resize_layer.cpp; then
    echo "PASS: crop_and_resize_layer.cpp has copyright header"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: crop_and_resize_layer.cpp should have copyright header" >&2
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
