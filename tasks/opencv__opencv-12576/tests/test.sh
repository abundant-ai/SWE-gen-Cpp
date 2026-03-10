#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/cudaarithm/test"
cp "/tests/modules/cudaarithm/test/test_element_operations.cpp" "modules/cudaarithm/test/test_element_operations.cpp"

checks_passed=0
checks_failed=0

# PR #12576: Add CV_64F (double precision) support to polarToCart
# For harbor testing:
# - HEAD (5db13fe2a7750592e829d4a4ec4c39ea03e948d2): Fixed version with CV_64F support
# - BASE (after bug.patch): Buggy version without CV_64F support (CV_32FC1 only)
# - FIXED (after oracle applies fix): Back to fixed version with CV_64F support

# Check 1: Header documentation SHOULD mention CV_64FC1 support (fixed version has it)
if grep -q '@param magnitude Source matrix containing magnitudes ( CV_32FC1 or CV_64FC1 )' modules/cudaarithm/include/opencv2/cudaarithm.hpp; then
    echo "PASS: Header documents CV_64FC1 support - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Header doesn't document CV_64FC1 support - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Header SHOULD NOT say CV_32FC1 only (buggy version has this)
if grep -q '@param magnitude Source matrix containing magnitudes ( CV_32FC1 )\.$' modules/cudaarithm/include/opencv2/cudaarithm.hpp; then
    echo "FAIL: Header shows CV_32FC1 only - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: Header doesn't restrict to CV_32FC1 only - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: Test file SHOULD test both CV_32FC1 and CV_64FC1 types (fixed version has both)
if grep -q 'DEF_PARAM_TEST(Sz_Type_AngleInDegrees, cv::Size, MatType, bool)' modules/cudaarithm/perf/perf_element_operations.cpp; then
    echo "PASS: Performance test defines Sz_Type_AngleInDegrees - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Performance test missing Sz_Type_AngleInDegrees - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Performance test SHOULD use Sz_Type_AngleInDegrees for PolarToCart (fixed version has it)
if grep -q 'PERF_TEST_P(Sz_Type_AngleInDegrees, PolarToCart,' modules/cudaarithm/perf/perf_element_operations.cpp; then
    echo "PASS: PolarToCart perf test uses Sz_Type_AngleInDegrees - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PolarToCart perf test doesn't use Sz_Type_AngleInDegrees - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Performance test SHOULD test both CV_32FC1 and CV_64FC1 (fixed version has it)
if grep -q 'testing::Values(CV_32FC1, CV_64FC1)' modules/cudaarithm/perf/perf_element_operations.cpp; then
    echo "PASS: Performance test includes CV_64FC1 type - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Performance test missing CV_64FC1 type - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: CUDA kernel SHOULD have template for type T (fixed version has it)
if grep -q 'template <typename T, bool useMag>' modules/cudaarithm/src/cuda/polar_cart.cu; then
    echo "PASS: CUDA kernel templated on type T - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CUDA kernel not templated on type T - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: CUDA kernel SHOULD NOT be hardcoded to float (buggy version has this)
if grep -q '__global__ void polarToCartImpl(const GlobPtr<float> mag, const GlobPtr<float> angle, GlobPtr<float> xmat, GlobPtr<float> ymat, const float scale' modules/cudaarithm/src/cuda/polar_cart.cu; then
    echo "FAIL: CUDA kernel hardcoded to float - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: CUDA kernel not hardcoded to float - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 8: polarToCart function SHOULD support both CV_32F and CV_64F (fixed version has it)
if grep -q 'CV_Assert(angle.depth() == CV_32F || angle.depth() == CV_64F)' modules/cudaarithm/src/cuda/polar_cart.cu; then
    echo "PASS: polarToCart accepts CV_32F or CV_64F - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: polarToCart doesn't accept CV_64F - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: polarToCart SHOULD NOT restrict to CV_32F only (buggy version has this)
if grep -q 'CV_Assert( angle.depth() == CV_32F );' modules/cudaarithm/src/cuda/polar_cart.cu; then
    echo "FAIL: polarToCart restricts to CV_32F only - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: polarToCart doesn't restrict to CV_32F only - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 10: Test file SHOULD test both CV_32FC1 and CV_64FC1 (fixed version has it)
if grep -q 'PARAM_TEST_CASE(PolarToCart, cv::cuda::DeviceInfo, cv::Size, MatType, AngleInDegrees, UseRoi)' modules/cudaarithm/test/test_element_operations.cpp; then
    echo "PASS: Test case includes MatType parameter - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test case missing MatType parameter - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: Test instantiation SHOULD include both CV_32FC1 and CV_64FC1 (fixed version has it)
if grep -A 4 'INSTANTIATE_TEST_CASE_P(CUDA_Arithm, PolarToCart, testing::Combine(' modules/cudaarithm/test/test_element_operations.cpp | grep -q 'testing::Values(CV_32FC1, CV_64FC1)'; then
    echo "PASS: Test instantiation includes CV_64FC1 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test instantiation missing CV_64FC1 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: sincos_op template SHOULD exist for double support (fixed version has it)
if grep -q 'template <typename T> struct sincos_op' modules/cudaarithm/src/cuda/polar_cart.cu; then
    echo "PASS: sincos_op template exists - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: sincos_op template missing - buggy version" >&2
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
