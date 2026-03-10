#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_imgproc_tests.hpp" "modules/gapi/test/common/gapi_imgproc_tests.hpp"
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_imgproc_tests_inl.hpp" "modules/gapi/test/common/gapi_imgproc_tests_inl.hpp"
mkdir -p "modules/gapi/test/cpu"
cp "/tests/modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp" "modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp"
mkdir -p "modules/gapi/test/cpu"
cp "/tests/modules/gapi/test/cpu/gapi_imgproc_tests_fluid.cpp" "modules/gapi/test/cpu/gapi_imgproc_tests_fluid.cpp"

checks_passed=0
checks_failed=0

# PR #13723 adds the SobelXY function to G-API
# HEAD (b7aaa053bc062e0bf63b4533edbc5b439dbf3d6d): Fixed version with SobelXY
# BASE (after bug.patch): Buggy version without SobelXY
# FIXED (after fix.patch): Fixed version (matches HEAD) with SobelXY

# Check 1: imgproc.hpp should have GMat2 typedef (fixed version)
if grep -q 'using GMat2 = std::tuple<GMat,GMat>;' modules/gapi/include/opencv2/gapi/imgproc.hpp; then
    echo "PASS: imgproc.hpp has GMat2 typedef (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgproc.hpp does not have GMat2 typedef (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: imgproc.hpp should have GSobelXY kernel (fixed version)
if grep -q 'G_TYPED_KERNEL_M(GSobelXY' modules/gapi/include/opencv2/gapi/imgproc.hpp; then
    echo "PASS: imgproc.hpp has GSobelXY kernel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgproc.hpp does not have GSobelXY kernel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: imgproc.hpp should have SobelXY function declaration (fixed version)
if grep -q 'GAPI_EXPORTS std::tuple<GMat, GMat> SobelXY' modules/gapi/include/opencv2/gapi/imgproc.hpp; then
    echo "PASS: imgproc.hpp has SobelXY function declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgproc.hpp does not have SobelXY function declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: kernels_imgproc.cpp should have SobelXY implementation (fixed version)
if grep -q 'std::tuple<GMat, GMat> SobelXY' modules/gapi/src/api/kernels_imgproc.cpp; then
    echo "PASS: kernels_imgproc.cpp has SobelXY implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: kernels_imgproc.cpp does not have SobelXY implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gcpuimgproc.cpp should have GCPUSobelXY kernel (fixed version)
if grep -q 'GAPI_OCV_KERNEL(GCPUSobelXY' modules/gapi/src/backends/cpu/gcpuimgproc.cpp; then
    echo "PASS: gcpuimgproc.cpp has GCPUSobelXY kernel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcpuimgproc.cpp does not have GCPUSobelXY kernel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: gcpuimgproc.cpp should have add_border helper function (fixed version)
if grep -q 'cv::Mat add_border' modules/gapi/src/backends/cpu/gcpuimgproc.cpp; then
    echo "PASS: gcpuimgproc.cpp has add_border helper (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcpuimgproc.cpp does not have add_border helper (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: gfluidimgproc.cpp should have GFluidSobelXY kernel (fixed version)
if grep -q 'GAPI_FLUID_KERNEL(GFluidSobelXY' modules/gapi/src/backends/fluid/gfluidimgproc.cpp; then
    echo "PASS: gfluidimgproc.cpp has GFluidSobelXY kernel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidimgproc.cpp does not have GFluidSobelXY kernel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gapi_imgproc_tests.hpp should have SobelXYTest class (fixed version)
if grep -q 'struct SobelXYTest' modules/gapi/test/common/gapi_imgproc_tests.hpp; then
    echo "PASS: gapi_imgproc_tests.hpp has SobelXYTest class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_imgproc_tests.hpp does not have SobelXYTest class (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: gapi_imgproc_tests_inl.hpp should have SobelXYTest implementation (fixed version)
if grep -q 'TEST_P(SobelXYTest, AccuracyTest)' modules/gapi/test/common/gapi_imgproc_tests_inl.hpp; then
    echo "PASS: gapi_imgproc_tests_inl.hpp has SobelXYTest implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_imgproc_tests_inl.hpp does not have SobelXYTest implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: gapi_imgproc_tests_cpu.cpp should have SobelXYTestCPU instantiation (fixed version)
if grep -q 'INSTANTIATE_TEST_CASE_P(SobelXYTestCPU' modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp; then
    echo "PASS: gapi_imgproc_tests_cpu.cpp has SobelXYTestCPU instantiation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_imgproc_tests_cpu.cpp does not have SobelXYTestCPU instantiation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: gapi_imgproc_tests_fluid.cpp should have SobelXYTestFluid instantiation (fixed version)
if grep -q 'INSTANTIATE_TEST_CASE_P(SobelXYTestFluid' modules/gapi/test/cpu/gapi_imgproc_tests_fluid.cpp; then
    echo "PASS: gapi_imgproc_tests_fluid.cpp has SobelXYTestFluid instantiation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_imgproc_tests_fluid.cpp does not have SobelXYTestFluid instantiation (buggy version)" >&2
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
