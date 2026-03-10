#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11700: Wrap Inference Engine init to try-catch and fix OpenCL target fallback

# Check 1: dnn.cpp should have conditional OpenCL->CPU fallback (not unconditional)
# In the buggy state, it was just "impl->preferableTarget = DNN_TARGET_CPU;"
# In the fixed state, it should be wrapped in a conditional checking the backend
if grep -A5 '#ifndef HAVE_OPENCL' modules/dnn/src/dnn.cpp | grep -q '#ifdef HAVE_INF_ENGINE'; then
    echo "PASS: dnn.cpp has conditional OpenCL fallback logic"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should have conditional OpenCL fallback (checking HAVE_INF_ENGINE)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: op_inf_engine.cpp should wrap initialization in try-catch
# The fixed version should have "try {" at the start of initPlugin
if grep -A10 'void InfEngineBackendNet::initPlugin' modules/dnn/src/op_inf_engine.cpp | grep -q 'try'; then
    echo "PASS: op_inf_engine.cpp wraps initialization in try-catch"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should wrap initialization in try-catch" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: perf_net.cpp should check both OPENCL and OPENCL_FP16
if grep -q 'target == DNN_TARGET_OPENCL || target == DNN_TARGET_OPENCL_FP16' modules/dnn/perf/perf_net.cpp; then
    echo "PASS: perf_net.cpp checks both OPENCL and OPENCL_FP16"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_net.cpp should check both OPENCL and OPENCL_FP16 targets" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_backends.cpp should check both OPENCL and OPENCL_FP16
if grep -q 'target == DNN_TARGET_OPENCL || target == DNN_TARGET_OPENCL_FP16' modules/dnn/test/test_backends.cpp; then
    echo "PASS: test_backends.cpp checks both OPENCL and OPENCL_FP16"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_backends.cpp should check both OPENCL and OPENCL_FP16 targets" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: op_inf_engine.cpp should have catch blocks handling exceptions
if grep -q 'catch' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp has catch blocks"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should have catch blocks for exception handling" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: dnn.cpp should NOT have unconditional fallback to CPU
# The buggy version just set CPU unconditionally, the fixed version has conditions
if ! grep -A2 '#ifndef HAVE_OPENCL' modules/dnn/src/dnn.cpp | grep -E '^\s+impl->preferableTarget = DNN_TARGET_CPU;$' | grep -v 'if.*preferableBackend' > /dev/null; then
    echo "PASS: dnn.cpp does not have unconditional CPU fallback"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should not have unconditional CPU fallback at the OpenCL check" >&2
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
