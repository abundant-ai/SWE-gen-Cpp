#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgproc/test/ocl"
cp "/tests/modules/imgproc/test/ocl/test_filters.cpp" "modules/imgproc/test/ocl/test_filters.cpp"

checks_passed=0
checks_failed=0

# PR #13167: The PR refactors OpenCV imgproc morphology operations
# For harbor testing:
# - HEAD (8409aa9ebace6a10d1e3eb7a7472d155160b7143): Refactored code (fixed version)
# - BASE (after bug.patch): Original code (buggy version)
# - FIXED (after fix.patch): Back to refactored code (back to HEAD)

# Check 1: morph.cpp should NOT have #ifndef __APPLE__ guard around ocl_morph3x3_8UC1
if grep -B 2 "static bool ocl_morph3x3_8UC1" modules/imgproc/src/morph.cpp | grep -q "#ifndef __APPLE__"; then
    echo "FAIL: morph.cpp has #ifndef __APPLE__ guard - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: morph.cpp does not have #ifndef __APPLE__ guard before ocl_morph3x3_8UC1 - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 2: morph.cpp should have param_use_morph_special_kernels configuration check
if grep -q "param_use_morph_special_kernels" modules/imgproc/src/morph.cpp; then
    echo "PASS: morph.cpp includes param_use_morph_special_kernels check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: morph.cpp missing param_use_morph_special_kernels check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: morph.cpp should include configuration.private.hpp
if grep -q "#include <opencv2/core/utils/configuration.private.hpp>" modules/imgproc/src/morph.cpp; then
    echo "PASS: morph.cpp includes configuration.private.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: morph.cpp missing configuration.private.hpp include - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: batch_norm_layer.cpp should include layers_common.hpp
if grep -q '#include "layers_common.hpp"' modules/dnn/src/layers/batch_norm_layer.cpp; then
    echo "PASS: batch_norm_layer.cpp includes layers_common.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: batch_norm_layer.cpp missing layers_common.hpp include - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: batch_norm_layer.cpp should use wV and bV variables in v_muladd
if grep "x0 = v_muladd(x0, wV, bV);" modules/dnn/src/layers/batch_norm_layer.cpp >/dev/null 2>&1; then
    echo "PASS: batch_norm_layer.cpp uses wV and bV in v_muladd - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: batch_norm_layer.cpp uses incorrect variables in v_muladd - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: elementwise_layers.cpp should NOT include opencv2/imgproc.hpp
if grep -q '#include "opencv2/imgproc.hpp"' modules/dnn/src/layers/elementwise_layers.cpp; then
    echo "FAIL: elementwise_layers.cpp includes opencv2/imgproc.hpp - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: elementwise_layers.cpp does not include opencv2/imgproc.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 7: dnn.cpp should have the preferableBackend check
if grep -A 2 "preferableBackend != DNN_BACKEND_OPENCV" modules/dnn/src/dnn.cpp | grep -q "continue;  // Go to the next layer."; then
    echo "PASS: dnn.cpp includes preferableBackend check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing preferableBackend check - buggy version" >&2
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
