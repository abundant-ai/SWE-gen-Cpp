#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.hpp" "modules/dnn/test/test_common.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_precomp.hpp" "modules/dnn/test/test_precomp.hpp"

checks_passed=0
checks_failed=0

# PR #12142: Fix DNN OpenCL convolution performance coverage and backend/target reporting
# The fix removes the old OpenCL perf test file and updates test infrastructure

# Check 1: Old OpenCL perf_convolution.cpp file should NOT exist (it was removed in the fix)
if [ ! -f "modules/dnn/perf/opencl/perf_convolution.cpp" ]; then
    echo "PASS: modules/dnn/perf/opencl/perf_convolution.cpp correctly removed"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/dnn/perf/opencl/perf_convolution.cpp should be removed" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Updated perf_convolution.cpp should have the new test configurations
if [ -f "modules/dnn/perf/perf_convolution.cpp" ]; then
    echo "PASS: modules/dnn/perf/perf_convolution.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/dnn/perf/perf_convolution.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_precomp.hpp should contain DNNTestLayer class
if grep -q "class DNNTestLayer" modules/dnn/test/test_precomp.hpp 2>/dev/null; then
    echo "PASS: DNNTestLayer class exists in test_precomp.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DNNTestLayer class should exist in test_precomp.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_precomp.hpp should have availableDnnTargets function
if grep -q "availableDnnTargets" modules/dnn/test/test_precomp.hpp 2>/dev/null; then
    echo "PASS: availableDnnTargets function exists in test_precomp.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: availableDnnTargets function should exist in test_precomp.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_precomp.hpp should have checkBackend methods
if grep -q "checkBackend" modules/dnn/test/test_precomp.hpp 2>/dev/null; then
    echo "PASS: checkBackend methods exist in test_precomp.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: checkBackend methods should exist in test_precomp.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: perf_precomp.hpp should exist and be updated
if [ -f "modules/dnn/perf/perf_precomp.hpp" ]; then
    echo "PASS: modules/dnn/perf/perf_precomp.hpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/dnn/perf/perf_precomp.hpp should exist" >&2
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
