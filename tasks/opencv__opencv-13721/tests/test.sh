#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_core_tests.hpp" "modules/gapi/test/common/gapi_core_tests.hpp"
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_core_tests_inl.hpp" "modules/gapi/test/common/gapi_core_tests_inl.hpp"
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_imgproc_tests_inl.hpp" "modules/gapi/test/common/gapi_imgproc_tests_inl.hpp"
mkdir -p "modules/gapi/test/cpu"
cp "/tests/modules/gapi/test/cpu/gapi_core_tests_cpu.cpp" "modules/gapi/test/cpu/gapi_core_tests_cpu.cpp"

checks_passed=0
checks_failed=0

# PR #13721 adds the normalize function to G-API
# HEAD (bcc1101dfddb472d2db9b2dccc05cd7fecfc4d1d): Fixed version with normalize
# BASE (after bug.patch): Buggy version without normalize
# FIXED (after fix.patch): Fixed version (matches HEAD) with normalize

# Check 1: core.hpp should have GNormalize kernel (fixed version)
if grep -q 'G_TYPED_KERNEL(GNormalize' modules/gapi/include/opencv2/gapi/core.hpp; then
    echo "PASS: core.hpp has GNormalize kernel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core.hpp does not have GNormalize kernel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: core.hpp should have normalize function declaration (fixed version)
if grep -q 'GAPI_EXPORTS GMat normalize' modules/gapi/include/opencv2/gapi/core.hpp; then
    echo "PASS: core.hpp has normalize function declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core.hpp does not have normalize function declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: kernels_core.cpp should have normalize implementation (fixed version)
if grep -q 'GMat normalize(const GMat& _src, double a, double b' modules/gapi/src/api/kernels_core.cpp; then
    echo "PASS: kernels_core.cpp has normalize implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: kernels_core.cpp does not have normalize implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: gcpucore.cpp should have GCPUNormalize kernel (fixed version)
if grep -q 'GAPI_OCV_KERNEL(GCPUNormalize' modules/gapi/src/backends/cpu/gcpucore.cpp; then
    echo "PASS: gcpucore.cpp has GCPUNormalize kernel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcpucore.cpp does not have GCPUNormalize kernel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gcpucore.cpp should register GCPUNormalize in kernel package (fixed version)
if grep -q ', GCPUNormalize' modules/gapi/src/backends/cpu/gcpucore.cpp; then
    echo "PASS: gcpucore.cpp registers GCPUNormalize in kernel package (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcpucore.cpp does not register GCPUNormalize in kernel package (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: gapi_core_tests.hpp should have NormalizeTest class (fixed version)
if grep -q 'struct NormalizeTest' modules/gapi/test/common/gapi_core_tests.hpp; then
    echo "PASS: gapi_core_tests.hpp has NormalizeTest class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_core_tests.hpp does not have NormalizeTest class (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: gapi_core_tests_inl.hpp should have NormalizeTest implementation (fixed version)
if grep -q 'TEST_P(NormalizeTest, Test)' modules/gapi/test/common/gapi_core_tests_inl.hpp; then
    echo "PASS: gapi_core_tests_inl.hpp has NormalizeTest implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_core_tests_inl.hpp does not have NormalizeTest implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gapi_core_tests_cpu.cpp should have NormalizeTestCPU instantiation (fixed version)
if grep -q 'INSTANTIATE_TEST_CASE_P(NormalizeTestCPU' modules/gapi/test/cpu/gapi_core_tests_cpu.cpp; then
    echo "PASS: gapi_core_tests_cpu.cpp has NormalizeTestCPU instantiation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_core_tests_cpu.cpp does not have NormalizeTestCPU instantiation (buggy version)" >&2
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
