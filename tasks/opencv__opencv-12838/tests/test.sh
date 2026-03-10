#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_fluid_resize_test.cpp" "modules/gapi/test/gapi_fluid_resize_test.cpp"

checks_passed=0
checks_failed=0

# PR #12838: Introduce LPI (Lines Per Iteration) support for Fluid resize operations
# For harbor testing:
# - HEAD (922d5796b90072d2c7a9b3ec659b7778eb79e652): Fixed version WITH LPI support
# - BASE (after bug.patch): Buggy version WITHOUT LPI support
# - FIXED (after fix.patch): Back to fixed version WITH LPI support

# Check 1: gfluidbackend.hpp SHOULD have setInHeight method in fixed version
if grep -q 'virtual void setInHeight(int h) = 0;' modules/gapi/src/backends/fluid/gfluidbackend.hpp; then
    echo "PASS: gfluidbackend.hpp has setInHeight method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbackend.hpp missing setInHeight method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gfluidbackend.cpp should have maxLineConsumption function (not maxReadWindow)
if grep -q 'static int maxLineConsumption(const cv::GFluidKernel& k, int inH, int outH, int lpi)' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: gfluidbackend.cpp has maxLineConsumption function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbackend.cpp missing maxLineConsumption function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: FluidResizeAgent SHOULD have setInHeight override
if grep -A10 'struct FluidResizeAgent' modules/gapi/src/backends/fluid/gfluidbackend.cpp | grep -q 'setInHeight'; then
    echo "PASS: FluidResizeAgent has setInHeight - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FluidResizeAgent missing setInHeight - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: FluidUpscaleAgent SHOULD have m_inH member variable
if grep -q 'int m_inH;' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: FluidUpscaleAgent has m_inH member - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FluidUpscaleAgent missing m_inH member - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: FluidResizeAgent::firstWindow should use lpi calculation
if grep -q 'auto lpi = std::min(m_outputLines - m_producedLines, k.m_lpi);' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: FluidResizeAgent::firstWindow uses lpi calculation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FluidResizeAgent::firstWindow uses simple calculation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: FluidUpscaleAgent::firstWindow should use m_inH (not in_views metadata)
if grep -q 'upscaleWindowEnd(outIdx + lpi - 1, m_ratio, m_inH)' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: FluidUpscaleAgent::firstWindow uses m_inH - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FluidUpscaleAgent::firstWindow uses in_views metadata - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Test file should have FResizeNN1Lpi kernel
if grep -q 'GAPI_FLUID_KERNEL(FResizeNN1Lpi, cv::gapi::core::GResize, false)' modules/gapi/test/gapi_fluid_resize_test.cpp; then
    echo "PASS: Test has FResizeNN1Lpi kernel name - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test has FResizeNN kernel name - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Test file SHOULD have ADD_RESIZE_KERNEL_WITH_LPI macro
if grep -q '#define ADD_RESIZE_KERNEL_WITH_LPI' modules/gapi/test/gapi_fluid_resize_test.cpp; then
    echo "PASS: Test has ADD_RESIZE_KERNEL_WITH_LPI macro - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test missing ADD_RESIZE_KERNEL_WITH_LPI macro - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: Test should use fluidResizeTestPackage WITH lpi parameter
if grep -q 'static auto fluidResizeTestPackage = \[\](int interpolation, cv::Size szIn, cv::Size szOut, int lpi = 1)' modules/gapi/test/gapi_fluid_resize_test.cpp; then
    echo "PASS: fluidResizeTestPackage has lpi parameter - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: fluidResizeTestPackage missing lpi parameter - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: ResizeTestFluid struct SHOULD have lpi in tuple
if grep -q 'struct ResizeTestFluid : public TestWithParam<std::tuple<int, int, cv::Size, std::tuple<cv::Size, cv::Rect>, int, double>>' modules/gapi/test/gapi_fluid_resize_test.cpp; then
    echo "PASS: ResizeTestFluid tuple includes lpi - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ResizeTestFluid tuple missing lpi - buggy version" >&2
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
