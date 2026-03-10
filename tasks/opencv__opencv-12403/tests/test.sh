#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #12403: Fix DNN layer implementations (Permute, Reorg, ShuffleChannel)
# For harbor testing:
# - HEAD (09fa7587258a8f9085255a27e8a787a2a383d96d): Fixed version with proper implementation
# - BASE (after bug.patch): Buggy version with issues
# - FIXED (after oracle applies fix): Back to fixed version
#
# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: permute_layer.cpp should NOT have checkCurrentOrder function (fixed version removed it)
if ! grep -q 'void checkCurrentOrder(int currentOrder)' modules/dnn/src/layers/permute_layer.cpp && \
   grep -q 'if (currentOrder < 0 || currentOrder > _numAxes)' modules/dnn/src/layers/permute_layer.cpp; then
    echo "PASS: permute_layer.cpp has inline validation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: permute_layer.cpp has incorrect structure - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: reorg_layer.cpp should have finalize method (fixed version)
if grep -q 'virtual void finalize(InputArrayOfArrays inputs_arr, OutputArrayOfArrays outputs_arr) CV_OVERRIDE' modules/dnn/src/layers/reorg_layer.cpp && \
   grep -q 'permute = PermuteLayer::create(permParams);' modules/dnn/src/layers/reorg_layer.cpp; then
    echo "PASS: reorg_layer.cpp has finalize method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp missing finalize method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: reorg_layer.cpp should use permute in forward_ocl (fixed version)
if grep -q 'inputs\[0\] = inputs\[0\].reshape(1, permuteInpShape.size()' modules/dnn/src/layers/reorg_layer.cpp && \
   grep -q 'permute->preferableTarget = preferableTarget;' modules/dnn/src/layers/reorg_layer.cpp; then
    echo "PASS: reorg_layer.cpp uses permute in forward_ocl - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp doesn't use permute properly - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: reorg_layer.cpp should have private permute member (fixed version)
if grep -q 'Ptr<PermuteLayer> permute;' modules/dnn/src/layers/reorg_layer.cpp && \
   grep -q 'std::vector<int> permuteInpShape, permuteOutShape;' modules/dnn/src/layers/reorg_layer.cpp; then
    echo "PASS: reorg_layer.cpp has private permute members - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg_layer.cpp missing private members - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: shuffle_channel_layer.cpp should have forward_ocl method (fixed version)
if grep -q 'bool forward_ocl(InputArrayOfArrays inps, OutputArrayOfArrays outs, OutputArrayOfArrays internals)' modules/dnn/src/layers/shuffle_channel_layer.cpp && \
   grep -q 'CV_OCL_RUN(IS_DNN_OPENCL_TARGET(preferableTarget)' modules/dnn/src/layers/shuffle_channel_layer.cpp; then
    echo "PASS: shuffle_channel_layer.cpp has forward_ocl - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shuffle_channel_layer.cpp missing forward_ocl - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: reorg.cl OpenCL kernel file should NOT exist (fixed version removes it)
if [ ! -f "modules/dnn/src/opencl/reorg.cl" ]; then
    echo "PASS: reorg.cl file removed - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reorg.cl file exists - buggy version" >&2
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
