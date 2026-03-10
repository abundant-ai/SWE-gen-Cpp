#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.hpp" "modules/dnn/test/test_common.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_misc.cpp" "modules/dnn/test/test_misc.cpp"

checks_passed=0
checks_failed=0

# PR #13181: The PR adds FPGA target support to OpenCV's DNN module with Inference Engine backend
# For harbor testing:
# - HEAD (0d117312c99759ef842f5cc4d2b4891f446bcbb7): DNN_TARGET_FPGA added (fixed version)
# - BASE (after bug.patch): DNN_TARGET_FPGA removed (buggy version)
# - FIXED (after fix.patch): DNN_TARGET_FPGA added back (back to HEAD)

# Check 1: dnn.hpp should include DNN_TARGET_FPGA in the Target enum
if grep -A 10 "enum Target" modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q "DNN_TARGET_FPGA"; then
    echo "PASS: dnn.hpp includes DNN_TARGET_FPGA in Target enum (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp missing DNN_TARGET_FPGA in Target enum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.hpp should document DNN_TARGET_FPGA in the compatibility table
if grep -q "DNN_TARGET_FPGA" modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -B 5 -A 1 "setPreferableTarget" modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q "DNN_TARGET_FPGA"; then
    echo "PASS: dnn.hpp documents DNN_TARGET_FPGA in compatibility table (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp missing DNN_TARGET_FPGA documentation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp should support DNN_TARGET_FPGA in preferableTarget validation
if grep -A 5 "preferableTarget == DNN_TARGET_CPU" modules/dnn/src/dnn.cpp | grep -q "preferableTarget == DNN_TARGET_FPGA"; then
    echo "PASS: dnn.cpp includes DNN_TARGET_FPGA in target validation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing DNN_TARGET_FPGA in target validation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn.cpp should handle FPGA in FP16 precision settings
if grep -B 2 -A 2 "preferableTarget == DNN_TARGET_MYRIAD" modules/dnn/src/dnn.cpp | grep -q "preferableTarget == DNN_TARGET_FPGA"; then
    echo "PASS: dnn.cpp includes DNN_TARGET_FPGA in FP16 precision handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing DNN_TARGET_FPGA in FP16 precision handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: op_inf_engine.cpp should support eFPGA device
if grep -A 3 "device != InferenceEngine::TargetDevice::eMYRIAD" modules/dnn/src/op_inf_engine.cpp | grep -q "device != InferenceEngine::TargetDevice::eFPGA"; then
    echo "PASS: op_inf_engine.cpp includes eFPGA device validation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp missing eFPGA device validation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: perf_net.cpp should use checkIETarget instead of checkMyriadTarget
if grep -q "checkIETarget(DNN_TARGET_MYRIAD)" modules/dnn/perf/perf_net.cpp; then
    echo "PASS: perf_net.cpp uses checkIETarget helper (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_net.cpp uses checkMyriadTarget instead of checkIETarget (buggy version)" >&2
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
