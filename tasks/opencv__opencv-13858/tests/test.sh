#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_fluid_resize_test.cpp" "modules/gapi/test/gapi_fluid_resize_test.cpp"
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_fluid_test.cpp" "modules/gapi/test/gapi_fluid_test.cpp"
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_fluid_test_kernels.cpp" "modules/gapi/test/gapi_fluid_test_kernels.cpp"

checks_passed=0
checks_failed=0

# PR #13858 adds NV12toRGB functionality to OpenCV's G-API fluid backend
# HEAD (c0076b58cd7b046484cc280548a6cc6c05975245): Fixed version with NV12toRGB support
# BASE (after bug.patch): Buggy version without NV12toRGB support
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: GFluidKernel::Kind enum should have NV12toRGB (fixed version)
if grep -q 'NV12toRGB' modules/gapi/include/opencv2/gapi/fluid/gfluidkernel.hpp; then
    echo "PASS: NV12toRGB enum value exists in gfluidkernel.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toRGB enum value missing from gfluidkernel.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: FluidNV12toRGBAgent should exist in backend (fixed version)
if grep -q 'struct FluidNV12toRGBAgent' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: FluidNV12toRGBAgent struct exists in gfluidbackend.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FluidNV12toRGBAgent struct missing from gfluidbackend.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: NV12toRGB case in borderSize function (fixed version)
if grep -q 'case cv::GFluidKernel::Kind::NV12toRGB:' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: NV12toRGB case exists in borderSize function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toRGB case missing from borderSize function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: line_consumption should be vector (fixed version - supports multiple ports)
if grep -q 'std::vector<int> line_consumption;' modules/gapi/src/backends/fluid/gfluidbackend.hpp; then
    echo "PASS: line_consumption is vector<int> in gfluidbackend.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: line_consumption is not vector<int> in gfluidbackend.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: firstWindow should take inPort parameter (fixed version)
if grep -q 'virtual int firstWindow(std::size_t inPort) const = 0;' modules/gapi/src/backends/fluid/gfluidbackend.hpp; then
    echo "PASS: firstWindow takes inPort parameter in gfluidbackend.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: firstWindow does not take inPort parameter in gfluidbackend.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test file should have NV12PlusResizeTest (fixed version)
if grep -q 'struct NV12PlusResizeTest' modules/gapi/test/gapi_fluid_resize_test.cpp; then
    echo "PASS: NV12PlusResizeTest exists in gapi_fluid_resize_test.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12PlusResizeTest missing from gapi_fluid_resize_test.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Test file should have NV12RoiTest (fixed version)
if grep -q 'struct NV12RoiTest' modules/gapi/test/gapi_fluid_test.cpp; then
    echo "PASS: NV12RoiTest exists in gapi_fluid_test.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12RoiTest missing from gapi_fluid_test.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: FNV12toRGB kernel should exist (fixed version)
if grep -q 'GAPI_FLUID_KERNEL(FNV12toRGB' modules/gapi/test/gapi_fluid_test_kernels.cpp; then
    echo "PASS: FNV12toRGB kernel exists in gapi_fluid_test_kernels.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FNV12toRGB kernel missing from gapi_fluid_test_kernels.cpp (buggy version)" >&2
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
