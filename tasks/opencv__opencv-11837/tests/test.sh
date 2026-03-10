#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_arithm.cpp" "modules/core/test/test_arithm.cpp"

checks_passed=0
checks_failed=0

# PR #11837: Extend findNonZero and improve PSNR behavior

# Check 1: core.hpp - findNonZero documentation should support single-channel arrays (not just CV_8UC1)
if grep -B 10 'CV_EXPORTS_W void findNonZero' modules/core/include/opencv2/core.hpp | grep -q '@param src single-channel array$'; then
    echo "PASS: findNonZero documentation shows support for single-channel arrays"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findNonZero should support single-channel arrays, not just CV_8UC1" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: core.hpp - PSNR should have R parameter with default value
if grep -q 'CV_EXPORTS_W double PSNR(InputArray src1, InputArray src2, double R=255.)' modules/core/include/opencv2/core.hpp; then
    echo "PASS: PSNR function signature includes R parameter with default value"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PSNR should have R parameter with default value 255" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: core.hpp - PSNR documentation should mention arrays must have same type (not just CV_8U)
if grep -A 5 'Computes the Peak Signal-to-Noise Ratio' modules/core/include/opencv2/core.hpp | grep -q 'The arrays must have the same type'; then
    echo "PASS: PSNR documentation mentions arrays must have same type"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PSNR documentation should mention arrays must have same type" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: count_non_zero.cpp - findNonZero should check channels==1 and dims==2 (not type==CV_8UC1)
if grep -q 'CV_Assert( src.channels() == 1 && src.dims == 2 )' modules/core/src/count_non_zero.cpp; then
    echo "PASS: findNonZero checks for single-channel and 2D, allowing multiple depth types"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findNonZero should use flexible assertion (channels==1 && dims==2)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: count_non_zero.cpp - findNonZero should handle multiple depth types
if grep -A 40 'void cv::findNonZero' modules/core/src/count_non_zero.cpp | grep -q 'if( depth == CV_8U || depth == CV_8S )'; then
    echo "PASS: findNonZero handles CV_8U and CV_8S depth types"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findNonZero should handle multiple depth types including CV_8U/CV_8S" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: count_non_zero.cpp - findNonZero should handle CV_16U and CV_16S
if grep -A 40 'void cv::findNonZero' modules/core/src/count_non_zero.cpp | grep -q 'else if( depth == CV_16U || depth == CV_16S )'; then
    echo "PASS: findNonZero handles CV_16U and CV_16S depth types"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findNonZero should handle CV_16U and CV_16S depth types" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: count_non_zero.cpp - findNonZero should handle CV_32F
if grep -A 40 'void cv::findNonZero' modules/core/src/count_non_zero.cpp | grep -q 'else if( depth == CV_32F )'; then
    echo "PASS: findNonZero handles CV_32F depth type"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findNonZero should handle CV_32F depth type" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: count_non_zero.cpp - findNonZero should use idxvec vector to accumulate results
if grep -A 40 'void cv::findNonZero' modules/core/src/count_non_zero.cpp | grep -q 'std::vector<Point> idxvec'; then
    echo "PASS: findNonZero uses vector to accumulate non-zero indices"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findNonZero should use std::vector<Point> idxvec" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: norm.cpp - PSNR should accept R parameter
if grep -q 'double cv::PSNR(InputArray _src1, InputArray _src2, double R)' modules/core/src/norm.cpp; then
    echo "PASS: PSNR implementation accepts R parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PSNR should accept R parameter in implementation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: norm.cpp - PSNR should check types match (not just depth==CV_8U)
if grep -A 5 'double cv::PSNR' modules/core/src/norm.cpp | grep -q 'CV_Assert( _src1.type() == _src2.type() )'; then
    echo "PASS: PSNR checks that input types match (flexible type support)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PSNR should check types match with CV_Assert(_src1.type() == _src2.type())" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: norm.cpp - PSNR should use R parameter in calculation (not hardcoded 255)
if grep -A 8 'double cv::PSNR' modules/core/src/norm.cpp | grep -q 'return 20\*log10(R/(diff+DBL_EPSILON))'; then
    echo "PASS: PSNR uses R parameter in calculation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PSNR should use R parameter in calculation, not hardcoded 255" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_arithm.cpp - Test should be named "regression" (comprehensive test)
if grep -q 'TEST(Core_FindNonZero, regression)' modules/core/test/test_arithm.cpp; then
    echo "PASS: Test is named 'regression' indicating comprehensive coverage"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should be named TEST(Core_FindNonZero, regression)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_arithm.cpp - Test should verify multiple depth types
if grep -A 60 'TEST(Core_FindNonZero, regression)' modules/core/test/test_arithm.cpp | grep -q 'img.convertTo( img, CV_8S )'; then
    echo "PASS: Test verifies CV_8S depth type support"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify CV_8S depth type conversion and support" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: test_arithm.cpp - Test should verify CV_16U depth type
if grep -A 60 'TEST(Core_FindNonZero, regression)' modules/core/test/test_arithm.cpp | grep -q 'img.convertTo( img, CV_16U )'; then
    echo "PASS: Test verifies CV_16U depth type support"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify CV_16U depth type conversion and support" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: test_arithm.cpp - Test should verify CV_32F depth type
if grep -A 60 'TEST(Core_FindNonZero, regression)' modules/core/test/test_arithm.cpp | grep -q 'img.convertTo( img, CV_32F )'; then
    echo "PASS: Test verifies CV_32F depth type support"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify CV_32F depth type conversion and support" >&2
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
