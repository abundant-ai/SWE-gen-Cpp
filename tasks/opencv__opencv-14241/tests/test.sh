#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# The fix updates InferenceEngine version from 2018R5 to 2019R1 throughout the codebase.
# We validate by checking source files for the fixed state (2019R1).

# Check 1: cmake/OpenCVDetectInferenceEngine.cmake should use 2019R1 as default (fixed version)
if grep -q 'message(WARNING "InferenceEngine version have not been set, 2019R1 will be used by default' cmake/OpenCVDetectInferenceEngine.cmake; then
    echo "PASS: cmake file uses 2019R1 as default (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cmake file missing 2019R1 default (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: cmake file should set INF_ENGINE_RELEASE to "2019010000" (fixed version)
if grep -q 'set(INF_ENGINE_RELEASE "2019010000"' cmake/OpenCVDetectInferenceEngine.cmake; then
    echo "PASS: cmake file sets INF_ENGINE_RELEASE to 2019010000 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cmake file missing 2019010000 setting (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: modules/dnn/src/dnn.cpp should use INF_ENGINE_VER_MAJOR_GE with 2019R1 (fixed version)
if grep -q 'INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1)' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp uses INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1) (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1) (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: modules/dnn/src/layers/normalize_bbox_layer.cpp should use GE with 2019R1 (fixed version)
if grep -q 'INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1)' modules/dnn/src/layers/normalize_bbox_layer.cpp; then
    echo "PASS: normalize_bbox_layer.cpp uses INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1) (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: normalize_bbox_layer.cpp missing INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1) (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: modules/dnn/src/op_inf_engine.cpp should use GE with 2019R1 (fixed version)
if grep -q 'INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1)' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp uses INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1) (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp missing INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2019R1) (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: modules/dnn/src/op_inf_engine.hpp should define INF_ENGINE_RELEASE_2019R1 (fixed version)
if grep -q '#define INF_ENGINE_RELEASE_2019R1 2019010000' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp defines INF_ENGINE_RELEASE_2019R1 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp missing INF_ENGINE_RELEASE_2019R1 definition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: modules/dnn/perf/perf_net.cpp should have skip condition for 2019R1 (fixed version)
if grep -q 'INF_ENGINE_VER_MAJOR_EQ(2019010000)' modules/dnn/perf/perf_net.cpp; then
    echo "PASS: perf_net.cpp has 2019R1 skip condition (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_net.cpp missing 2019R1 skip condition (buggy version)" >&2
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
