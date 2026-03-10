#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_imgproc_tests.hpp" "modules/gapi/test/common/gapi_imgproc_tests.hpp"
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_imgproc_tests_inl.hpp" "modules/gapi/test/common/gapi_imgproc_tests_inl.hpp"
mkdir -p "modules/gapi/test/cpu"
cp "/tests/modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp" "modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp"

checks_passed=0
checks_failed=0

# PR #13838 adds NV12toRGB and NV12toBGR color conversion functions to G-API
# HEAD (406392e13d5542c9787b4b8b31d251b313468234): Fixed version with NV12 conversions
# BASE (after bug.patch): Buggy version without NV12 conversions
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: GNV12toRGB kernel should exist in header (fixed version)
if grep -q 'G_TYPED_KERNEL(GNV12toRGB' modules/gapi/include/opencv2/gapi/imgproc.hpp; then
    echo "PASS: GNV12toRGB kernel exists in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: GNV12toRGB kernel missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: GNV12toBGR kernel should exist in header (fixed version)
if grep -q 'G_TYPED_KERNEL(GNV12toBGR' modules/gapi/include/opencv2/gapi/imgproc.hpp; then
    echo "PASS: GNV12toBGR kernel exists in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: GNV12toBGR kernel missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: NV12toRGB API function should exist (fixed version)
if grep -q 'GAPI_EXPORTS GMat NV12toRGB' modules/gapi/include/opencv2/gapi/imgproc.hpp; then
    echo "PASS: NV12toRGB API function declared in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toRGB API function missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: NV12toBGR API function should exist (fixed version)
if grep -q 'GAPI_EXPORTS GMat NV12toBGR' modules/gapi/include/opencv2/gapi/imgproc.hpp; then
    echo "PASS: NV12toBGR API function declared in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toBGR API function missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: NV12toRGB implementation should exist in kernels_imgproc.cpp (fixed version)
if grep -q 'GMat NV12toRGB(const GMat& src_y, const GMat& src_uv)' modules/gapi/src/api/kernels_imgproc.cpp; then
    echo "PASS: NV12toRGB implementation exists in kernels_imgproc.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toRGB implementation missing from kernels_imgproc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: NV12toBGR implementation should exist in kernels_imgproc.cpp (fixed version)
if grep -q 'GMat NV12toBGR(const GMat& src_y, const GMat& src_uv)' modules/gapi/src/api/kernels_imgproc.cpp; then
    echo "PASS: NV12toBGR implementation exists in kernels_imgproc.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toBGR implementation missing from kernels_imgproc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: GCPUNV12toRGB CPU kernel should exist (fixed version)
if grep -q 'GAPI_OCV_KERNEL(GCPUNV12toRGB, cv::gapi::imgproc::GNV12toRGB)' modules/gapi/src/backends/cpu/gcpuimgproc.cpp; then
    echo "PASS: GCPUNV12toRGB CPU kernel exists in gcpuimgproc.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: GCPUNV12toRGB CPU kernel missing from gcpuimgproc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: GCPUNV12toBGR CPU kernel should exist (fixed version)
if grep -q 'GAPI_OCV_KERNEL(GCPUNV12toBGR, cv::gapi::imgproc::GNV12toBGR)' modules/gapi/src/backends/cpu/gcpuimgproc.cpp; then
    echo "PASS: GCPUNV12toBGR CPU kernel exists in gcpuimgproc.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: GCPUNV12toBGR CPU kernel missing from gcpuimgproc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: Kernels should be registered in kernel package (fixed version)
if grep -q 'GCPUNV12toRGB' modules/gapi/src/backends/cpu/gcpuimgproc.cpp | tail -1; then
    echo "PASS: GCPUNV12toRGB registered in kernel package (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: GCPUNV12toRGB not registered in kernel package (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: NV12toRGBTest should exist in test header (fixed version)
if grep -q 'struct NV12toRGBTest' modules/gapi/test/common/gapi_imgproc_tests.hpp; then
    echo "PASS: NV12toRGBTest exists in gapi_imgproc_tests.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toRGBTest missing from gapi_imgproc_tests.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: NV12toBGRTest should exist in test header (fixed version)
if grep -q 'struct NV12toBGRTest' modules/gapi/test/common/gapi_imgproc_tests.hpp; then
    echo "PASS: NV12toBGRTest exists in gapi_imgproc_tests.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toBGRTest missing from gapi_imgproc_tests.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: NV12toRGB test implementation should exist (fixed version)
if grep -q 'TEST_P(NV12toRGBTest, AccuracyTest)' modules/gapi/test/common/gapi_imgproc_tests_inl.hpp; then
    echo "PASS: NV12toRGBTest implementation exists in gapi_imgproc_tests_inl.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toRGBTest implementation missing from gapi_imgproc_tests_inl.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: NV12toBGR test implementation should exist (fixed version)
if grep -q 'TEST_P(NV12toBGRTest, AccuracyTest)' modules/gapi/test/common/gapi_imgproc_tests_inl.hpp; then
    echo "PASS: NV12toBGRTest implementation exists in gapi_imgproc_tests_inl.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toBGRTest implementation missing from gapi_imgproc_tests_inl.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: NV12toRGBTestCPU instantiation should exist (fixed version)
if grep -q 'INSTANTIATE_TEST_CASE_P(NV12toRGBTestCPU, NV12toRGBTest' modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp; then
    echo "PASS: NV12toRGBTestCPU instantiation exists in gapi_imgproc_tests_cpu.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toRGBTestCPU instantiation missing from gapi_imgproc_tests_cpu.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: NV12toBGRTestCPU instantiation should exist (fixed version)
if grep -q 'INSTANTIATE_TEST_CASE_P(NV12toBGRTestCPU, NV12toBGRTest' modules/gapi/test/cpu/gapi_imgproc_tests_cpu.cpp; then
    echo "PASS: NV12toBGRTestCPU instantiation exists in gapi_imgproc_tests_cpu.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: NV12toBGRTestCPU instantiation missing from gapi_imgproc_tests_cpu.cpp (buggy version)" >&2
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
