#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13882 fixes deconvolution group handling in ONNX importer and convolution layer
# HEAD (bfd663c281f684fddf72db517f5d6f2b1f5e0cff): Fixed version with proper group handling
# BASE (after bug.patch): Buggy version with incorrect num_output calculation and internal shape handling
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: num_output should be multiplied by group in onnx_importer.cpp (fixed version)
if grep -A 2 'layerParams.blobs.push_back(getBlob(node_proto, constBlobs, j));' modules/dnn/src/onnx/onnx_importer.cpp | grep -q 'layerParams.set("num_output", layerParams.blobs\[0\].size\[1\] \* layerParams.get<int>("group", 1));'; then
    echo "PASS: num_output multiplied by group in onnx_importer.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: num_output not multiplied by group in onnx_importer.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: convolution_layer.cpp should use internals.push_back for col/row shape (fixed version)
if grep -A 2 'if (!is1x1())' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'internals.push_back(computeColRowShape(inputs\[0\], outputs\[0\]));'; then
    echo "PASS: convolution_layer.cpp uses push_back for col/row shape (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp does not use push_back for col/row shape (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: convolution_layer.cpp should NOT have internals.push_back(MatShape()) before is1x1() check (fixed version)
if ! grep -B 1 'if (!is1x1())' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'internals.push_back(MatShape());'; then
    echo "PASS: convolution_layer.cpp does not have empty push_back before is1x1() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp has empty push_back before is1x1() (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: convolution_layer.cpp should NOT use internals[0] assignment (fixed version)
if ! grep -A 2 'if (!is1x1())' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'internals\[0\] = computeColRowShape'; then
    echo "PASS: convolution_layer.cpp does not use internals[0] assignment (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp uses internals[0] assignment (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_onnx_importer.cpp should have deconvolution_group test (fixed version)
if grep -A 2 'testONNXModels("two_deconvolution");' modules/dnn/test/test_onnx_importer.cpp | grep -q 'testONNXModels("deconvolution_group");'; then
    echo "PASS: test_onnx_importer.cpp has deconvolution_group test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp missing deconvolution_group test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: convolution_layer.cpp should NOT have bias internals handling (fixed version)
if ! grep -A 4 'if (!is1x1())' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'if (hasBias())'; then
    echo "PASS: convolution_layer.cpp does not have bias internals handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp has bias internals handling (buggy version)" >&2
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
