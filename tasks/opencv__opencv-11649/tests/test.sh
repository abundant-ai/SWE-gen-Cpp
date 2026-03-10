#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11649: Fix PReLU layer with depthwise convolution + BatchNorm

# Check 1: convolution_layer.cpp should have bounds check for r1
if grep -A3 'if( relu )' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'if( i+1 >= outCn )'; then
    echo "PASS: convolution_layer.cpp has bounds check for r1"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp should have bounds check for r1" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: convolution_layer.cpp should set r1 = r0 when out of bounds
if grep -A4 'if( relu )' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'r1 = r0'; then
    echo "PASS: convolution_layer.cpp sets r1 = r0 when out of bounds"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp should set r1 = r0 when out of bounds" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: layers_common.simd.hpp should have bounds check for r2
if grep -A5 'if( relu )' modules/dnn/src/layers/layers_common.simd.hpp | grep -q 'if( i+2 >= outCn )'; then
    echo "PASS: layers_common.simd.hpp has bounds check for r2"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: layers_common.simd.hpp should have bounds check for r2" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: layers_common.simd.hpp should set r2 = r1 when i+2 out of bounds
if grep -A7 'if( relu )' modules/dnn/src/layers/layers_common.simd.hpp | grep -q 'r2 = r1'; then
    echo "PASS: layers_common.simd.hpp sets r2 = r1 when i+2 out of bounds"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: layers_common.simd.hpp should set r2 = r1 when i+2 out of bounds" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: layers_common.simd.hpp should have nested check for r1
if grep -A8 'if( relu )' modules/dnn/src/layers/layers_common.simd.hpp | grep -q 'if( i+1 >= outCn )'; then
    echo "PASS: layers_common.simd.hpp has nested bounds check for r1"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: layers_common.simd.hpp should have nested bounds check for r1" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: layers_common.simd.hpp should set r2 = r1 = r0 when both out of bounds
if grep -A9 'if( relu )' modules/dnn/src/layers/layers_common.simd.hpp | grep -q 'r2 = r1 = r0'; then
    echo "PASS: layers_common.simd.hpp sets r2 = r1 = r0 when both out of bounds"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: layers_common.simd.hpp should set r2 = r1 = r0 when both out of bounds" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_layers.cpp should have the Layer_Test_DWconv_Prelu test
if grep -q 'typedef TestWithParam<tuple<int, int> > Layer_Test_DWconv_Prelu' modules/dnn/test/test_layers.cpp; then
    echo "PASS: test_layers.cpp has Layer_Test_DWconv_Prelu test typedef"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp should have Layer_Test_DWconv_Prelu test typedef" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_layers.cpp should have TEST_P for Layer_Test_DWconv_Prelu
if grep -q 'TEST_P(Layer_Test_DWconv_Prelu, Accuracy)' modules/dnn/test/test_layers.cpp; then
    echo "PASS: test_layers.cpp has TEST_P for Layer_Test_DWconv_Prelu"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp should have TEST_P for Layer_Test_DWconv_Prelu" >&2
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
