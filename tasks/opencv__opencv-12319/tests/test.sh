#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
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

# PR #12319: Add support for Inference Engine 2018R3
# For harbor testing:
# - HEAD (3e027df5832ddb135f144d28b81c19bdf8a40133): Fixed version with IE 2018R3 support
# - BASE (after bug.patch): Buggy version without IE 2018R3 support
# - FIXED (after oracle applies fix): Back to fixed version with IE 2018R3 support

# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: op_inf_engine.hpp should have INF_ENGINE_RELEASE_2018R3 macro (fixed version)
if grep -q '#define INF_ENGINE_RELEASE_2018R3 2018030000' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp has INF_ENGINE_RELEASE_2018R3 macro - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp should have INF_ENGINE_RELEASE_2018R3 macro - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: op_inf_engine.hpp should have INF_ENGINE_VER_MAJOR_GE macro (fixed version)
if grep -q '#define INF_ENGINE_VER_MAJOR_GE(ver)' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp has INF_ENGINE_VER_MAJOR_GE macro - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp should have INF_ENGINE_VER_MAJOR_GE macro - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp should NOT have forceCreate parameter in allocateBlobsForLayer (fixed version removes it)
if grep -q 'bool forceCreate = false, bool use_half = false' modules/dnn/src/dnn.cpp; then
    echo "FAIL: dnn.cpp still has forceCreate parameter - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: dnn.cpp does not have forceCreate parameter - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: dnn.cpp should NOT pass forceCreate to reuseOrCreate (fixed version removes it)
if grep -q 'reuseOrCreate(shapes\[index\], blobPin, \*blobs\[index\], forceCreate, use_half)' modules/dnn/src/dnn.cpp; then
    echo "FAIL: dnn.cpp still passes forceCreate to reuseOrCreate - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: dnn.cpp does not pass forceCreate to reuseOrCreate - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: dnn.cpp should NOT have the DNN_BACKEND_INFERENCE_ENGINE line in allocateBlobsForLayer call (fixed version removes it)
if grep -B 1 'preferableBackend == DNN_BACKEND_OPENCV &&' modules/dnn/src/dnn.cpp | grep -q 'preferableBackend == DNN_BACKEND_INFERENCE_ENGINE,'; then
    echo "FAIL: dnn.cpp still has DNN_BACKEND_INFERENCE_ENGINE in allocateBlobsForLayer - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: dnn.cpp does not have DNN_BACKEND_INFERENCE_ENGINE in allocateBlobsForLayer - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 6: convolution_layer.cpp should have INF_ENGINE_VER_MAJOR_GE check (fixed version)
if grep -q 'INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2018R3)' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp has INF_ENGINE_VER_MAJOR_GE check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp should have INF_ENGINE_VER_MAJOR_GE check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: elementwise_layers.cpp should support INFERENCE_ENGINE backend for ELU (fixed version)
if grep -q 'backendId == DNN_BACKEND_INFERENCE_ENGINE' modules/dnn/src/layers/elementwise_layers.cpp && \
   grep -q 'lp.type = "ELU"' modules/dnn/src/layers/elementwise_layers.cpp; then
    echo "PASS: elementwise_layers.cpp supports INFERENCE_ENGINE backend for ELU - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: elementwise_layers.cpp should support INFERENCE_ENGINE backend for ELU - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: tf_importer.cpp should handle Pad in the main conditional block (fixed version)
if grep -q 'if (type == "Conv2D" || type == "SpaceToBatchND" || type == "DepthwiseConv2dNative" || type == "Pad")' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp handles Pad in main conditional - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should handle Pad in main conditional - buggy version" >&2
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
