#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_compoundkernel_tests.cpp" "modules/gapi/test/common/gapi_compoundkernel_tests.cpp"
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_fluid_resize_test.cpp" "modules/gapi/test/gapi_fluid_resize_test.cpp"
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_kernel_tests.cpp" "modules/gapi/test/gapi_kernel_tests.cpp"
mkdir -p "modules/gapi/test/internal"
cp "/tests/modules/gapi/test/internal/gapi_int_recompilation_test.cpp" "modules/gapi/test/internal/gapi_int_recompilation_test.cpp"

checks_passed=0
checks_failed=0

# PR #13851 introduces cv::gapi::use_only() API and removes obsolete GLookupOrder/unite_policy APIs
# HEAD (3c59d1f8a1b395f4de7ce89f6c3c67754985f2c4): Fixed version with use_only API
# BASE (after bug.patch): Buggy version with old GLookupOrder/unite_policy APIs
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: use_only struct should exist in gkernel.hpp (fixed version)
if grep -q 'struct GAPI_EXPORTS use_only' modules/gapi/include/opencv2/gapi/gkernel.hpp; then
    echo "PASS: use_only struct exists in gkernel.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: use_only struct missing from gkernel.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: GLookupOrder should NOT exist (fixed version removes it)
if grep -q 'using GLookupOrder' modules/gapi/include/opencv2/gapi/gkernel.hpp; then
    echo "FAIL: GLookupOrder still exists in gkernel.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: GLookupOrder removed from gkernel.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: lookup_order function should NOT exist (fixed version removes it)
if grep -q 'inline GLookupOrder lookup_order' modules/gapi/include/opencv2/gapi/gkernel.hpp; then
    echo "FAIL: lookup_order function still exists in gkernel.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: lookup_order function removed from gkernel.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: unite_policy enum should NOT exist (fixed version removes it)
if grep -q 'enum class unite_policy' modules/gapi/include/opencv2/gapi/gkernel.hpp; then
    echo "FAIL: unite_policy enum still exists in gkernel.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: unite_policy enum removed from gkernel.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: CompileArgTag specialization for use_only should exist (fixed version)
if grep -q 'struct CompileArgTag<cv::gapi::use_only>' modules/gapi/include/opencv2/gapi/gkernel.hpp; then
    echo "PASS: CompileArgTag<use_only> specialization exists in gkernel.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CompileArgTag<use_only> specialization missing from gkernel.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test file should use cv::gapi::use_only (fixed version)
if grep -q 'cv::gapi::use_only' modules/gapi/test/gapi_kernel_tests.cpp; then
    echo "PASS: cv::gapi::use_only used in gapi_kernel_tests.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cv::gapi::use_only missing from gapi_kernel_tests.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Documentation should not reference lookup_order (fixed version)
if grep -q 'cv::gapi::lookup_order' modules/gapi/include/opencv2/gapi/cpu/gcpukernel.hpp; then
    echo "FAIL: lookup_order reference still in gcpukernel.hpp documentation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: lookup_order reference removed from gcpukernel.hpp documentation (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 8: Documentation should not reference unite_policy (fixed version)
if grep -q 'cv::unite_policy' doc/tutorials/gapi/anisotropic_segmentation/porting_anisotropic_segmentation.markdown; then
    echo "FAIL: unite_policy reference still in documentation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: unite_policy reference removed from documentation (fixed version)"
    checks_passed=$((checks_passed + 1))
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
