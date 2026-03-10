#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"

checks_passed=0
checks_failed=0

# PR #13799 fixes Inference Engine compatibility issues
# HEAD (0711dab09ddf5a549be6e542150d0b8f90e0e783): Fixed version with proper type definitions
# BASE (after bug.patch): Buggy version with incorrect return types and missing macros
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: INF_ENGINE_VER_MAJOR_EQ macro should be defined (fixed version)
if grep -q '#define INF_ENGINE_VER_MAJOR_EQ(ver) (((INF_ENGINE_RELEASE) / 10000) == ((ver) / 10000))' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: INF_ENGINE_VER_MAJOR_EQ macro defined in op_inf_engine.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: INF_ENGINE_VER_MAJOR_EQ macro missing from op_inf_engine.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: convertFp16 return type should be InferenceEngine::Blob::Ptr (fixed version)
if grep -q 'InferenceEngine::Blob::Ptr convertFp16(const InferenceEngine::Blob::Ptr& blob);' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: convertFp16 has correct return type in op_inf_engine.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convertFp16 has incorrect return type in op_inf_engine.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: convertFp16 implementation return type should be InferenceEngine::Blob::Ptr (fixed version)
if grep -q 'InferenceEngine::Blob::Ptr convertFp16(const InferenceEngine::Blob::Ptr& blob)' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: convertFp16 implementation has correct return type in op_inf_engine.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convertFp16 implementation has incorrect return type in op_inf_engine.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: INF_ENGINE_VER_MAJOR_EQ should be used in dnn.cpp (fixed version)
if grep -q '#if INF_ENGINE_VER_MAJOR_EQ(INF_ENGINE_RELEASE_2018R4)' modules/dnn/src/dnn.cpp; then
    echo "PASS: INF_ENGINE_VER_MAJOR_EQ used correctly in dnn.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: INF_ENGINE_VER_MAJOR_EQ not used correctly in dnn.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: INF_ENGINE_VER_MAJOR_GT(INF_ENGINE_RELEASE_2018R5) block should exist in dnn.cpp (fixed version)
if grep -q '#if INF_ENGINE_VER_MAJOR_GT(INF_ENGINE_RELEASE_2018R5)' modules/dnn/src/dnn.cpp && \
   grep -q 'bool hasWeights = false;' modules/dnn/src/dnn.cpp; then
    echo "PASS: INF_ENGINE_VER_MAJOR_GT(2018R5) conditional compilation exists in dnn.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: INF_ENGINE_VER_MAJOR_GT(2018R5) conditional compilation missing from dnn.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: normalize_bbox_layer.cpp should have INF_ENGINE_VER_MAJOR_GT conditional (fixed version)
if grep -q '#if INF_ENGINE_VER_MAJOR_GT(INF_ENGINE_RELEASE_2018R5)' modules/dnn/src/layers/normalize_bbox_layer.cpp && \
   grep -q 'l.getParameters()\["weights"\] = (InferenceEngine::Blob::CPtr)weights;' modules/dnn/src/layers/normalize_bbox_layer.cpp; then
    echo "PASS: normalize_bbox_layer.cpp has correct conditional compilation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp missing conditional compilation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: resize_layer.cpp should use 1.0f instead of 1.0 (fixed version)
if grep -q 'ieLayer.getParameters()\["factor"\] = 1.0f / scaleWidth;' modules/dnn/src/layers/resize_layer.cpp; then
    echo "PASS: resize_layer.cpp uses 1.0f for factor calculation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize_layer.cpp uses incorrect type for factor (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Test skip should be present in Eltwise test (fixed version)
# The bug.patch REMOVES the skip condition, so in BASE it's absent
# The HEAD version (which Oracle restores via /tests copy) has the skip present
if grep -A 20 'TEST_P(Eltwise, Accuracy)' modules/dnn/test/test_halide_layers.cpp | grep -q 'INF_ENGINE_RELEASE > 2018050000'; then
    echo "PASS: Test skip correctly present in test_halide_layers.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test skip missing from test_halide_layers.cpp (buggy version)" >&2
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
