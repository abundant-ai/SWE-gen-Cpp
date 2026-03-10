#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13065: Fix for DNN layer fusion optimization
# For harbor testing:
# - HEAD (dc9e6d3af872bb35c0166771dc8a1d212318079f): Fixed version with correct layer fusion logic
# - BASE (after bug.patch): Buggy version with incorrect fusion condition
# - FIXED (after fix.patch): Back to fixed version

# Check 1: dnn.cpp should have type check for Convolution layer (line ~1797)
if grep -q 'IS_DNN_OPENCL_TARGET(preferableTarget) && ld.layerInstance->type == "Convolution"' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp has Convolution type check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing Convolution type check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.cpp should check inputBlobsId.size() == 2 (line ~1805)
if grep -q 'nextData->inputBlobsId.size() == 2' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp checks inputBlobsId.size() == 2 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing inputBlobsId.size() check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp should have biasLayerData variable (line ~1810)
if grep -q 'LayerData\* biasLayerData = 0;' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp has biasLayerData variable - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing biasLayerData variable - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn.cpp should have loop 'for (int i = 0; i < 2; ++i)' (line ~1811)
if grep -q 'for (int i = 0; i < 2; ++i)' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp has bias layer detection loop - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing bias layer detection loop - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dnn.cpp should check 'downLayerData->inputBlobsId.size() == 1' (line ~1817)
if grep -q 'downLayerData->inputBlobsId.size() == 1' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp checks downLayerData->inputBlobsId.size() - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing downLayerData->inputBlobsId.size() check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: dnn.cpp should use CV_Assert_N instead of CV_Assert (line ~1850)
if grep -q 'CV_Assert_N(biasLayerData->outputBlobsWrappers.size() == 1, ld.inputBlobsWrappers.size() == 1);' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp uses CV_Assert_N - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing CV_Assert_N - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: dnn.cpp should use biasLayerData instead of firstConvLayerData (line ~1851)
if grep -q 'ld.inputBlobsWrappers.push_back(biasLayerData->outputBlobsWrappers\[0\]);' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp uses biasLayerData - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp using wrong layer data - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: dnn.cpp should check 'biasLayerData->id < ld.id' (line ~1838)
if grep -q 'if (biasLayerData->id < ld.id)' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp checks biasLayerData->id - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing biasLayerData->id check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: dnn.cpp should NOT have 'if (preferableBackend != DNN_BACKEND_OPENCV) continue;'
# This line is removed in the fixed version (added in buggy version at line ~1900-1901)
if ! grep -B 5 '// the optimization #2' modules/dnn/src/dnn.cpp | grep -q 'if (preferableBackend != DNN_BACKEND_OPENCV)'; then
    echo "PASS: dnn.cpp does not have premature backend check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp has premature backend check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: pooling_layer.cpp should NOT have computeMaxIdx flag (removed in buggy version)
if ! grep -q 'bool computeMaxIdx;' modules/dnn/src/layers/pooling_layer.cpp; then
    echo "FAIL: pooling_layer.cpp missing computeMaxIdx - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: pooling_layer.cpp has computeMaxIdx - fixed version"
    checks_passed=$((checks_passed + 1))
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
