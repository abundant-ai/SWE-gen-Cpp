#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/video/test"
cp "/tests/modules/video/test/test_ecc.cpp" "modules/video/test/test_ecc.cpp"

checks_passed=0
checks_failed=0

# PR #13837 adds computeECC function and gaussFiltSize parameter to findTransformECC
# HEAD (9cd70e711699ae2a426b10d14187d60b22f6585c): Fixed version with new functions
# BASE (after bug.patch): Buggy version without new functions
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: computeECC function declaration should exist in header (fixed version)
if grep -q 'CV_EXPORTS_W double computeECC(InputArray templateImage, InputArray inputImage, InputArray inputMask = noArray());' modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: computeECC function declared in tracking.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: computeECC function missing from tracking.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: computeECC implementation should exist in ecc.cpp (fixed version)
if grep -q 'double cv::computeECC(InputArray templateImage, InputArray inputImage, InputArray inputMask)' modules/video/src/ecc.cpp; then
    echo "PASS: computeECC implementation exists in ecc.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: computeECC implementation missing from ecc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: findTransformECC with gaussFiltSize parameter should exist (fixed version)
if grep -q 'CV_EXPORTS_W double findTransformECC( InputArray templateImage, InputArray inputImage,' modules/video/include/opencv2/video/tracking.hpp | head -1 && \
   grep -q 'InputArray inputMask, int gaussFiltSize);' modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: findTransformECC with gaussFiltSize parameter declared in tracking.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findTransformECC with gaussFiltSize parameter missing from tracking.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: findTransformECC overload should exist (fixed version)
if grep -q 'double findTransformECC(InputArray templateImage, InputArray inputImage,' modules/video/include/opencv2/video/tracking.hpp | tail -1 && \
   grep -q 'InputArray inputMask = noArray());' modules/video/include/opencv2/video/tracking.hpp | tail -1; then
    echo "PASS: findTransformECC overload declared in tracking.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findTransformECC overload missing from tracking.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gaussFiltSize parameter should be used in implementation (fixed version)
if grep -q 'GaussianBlur(templateFloat, templateFloat, Size(gaussFiltSize, gaussFiltSize), 0, 0);' modules/video/src/ecc.cpp; then
    echo "PASS: gaussFiltSize parameter used in ecc.cpp implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gaussFiltSize parameter not used in ecc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Overload implementation calling main function with default value (fixed version)
if grep -q 'return findTransformECC(templateImage, inputImage, warpMatrix, motionType, criteria, inputMask, 5);' modules/video/src/ecc.cpp; then
    echo "PASS: findTransformECC overload implementation with default gaussFiltSize exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findTransformECC overload implementation missing from ecc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Test for computeECC should exist in test file (fixed version)
if grep -q 'TEST(Video_ECC_Test_Compute, accuracy)' modules/video/test/test_ecc.cpp; then
    echo "PASS: computeECC test exists in test_ecc.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: computeECC test missing from test_ecc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Test for gaussFiltSize parameter should exist (fixed version)
if grep -q 'findTransformECC(warpedImage, testImg, mapTranslation, 0,' modules/video/test/test_ecc.cpp && \
   grep -q 'TermCriteria(TermCriteria::COUNT+TermCriteria::EPS, ECC_iterations, ECC_epsilon), mask, 1);' modules/video/test/test_ecc.cpp; then
    echo "PASS: gaussFiltSize parameter test exists in test_ecc.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gaussFiltSize parameter test missing from test_ecc.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: Documentation for gaussFiltSize should exist (fixed version)
if grep -q '@param gaussFiltSize An optional value indicating size of gaussian blur filter; (DEFAULT: 5)' modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: gaussFiltSize documentation exists in tracking.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gaussFiltSize documentation missing from tracking.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: computeECC should be referenced in @sa section (fixed version)
if grep -q 'computeECC, estimateAffine2D' modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: computeECC referenced in @sa section (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: computeECC not referenced in @sa section (buggy version)" >&2
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
