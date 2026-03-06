#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_grfmt.cpp" "modules/imgcodecs/test/test_grfmt.cpp"
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_precomp.hpp" "modules/imgcodecs/test/test_precomp.hpp"

checks_passed=0
checks_failed=0

# Check 1: IMWRITE_BMP_COMPRESSION should be added to imgcodecs.hpp (fixed version)
if grep -q 'IMWRITE_BMP_COMPRESSION' modules/imgcodecs/include/opencv2/imgcodecs.hpp; then
    echo "PASS: imgcodecs.hpp has IMWRITE_BMP_COMPRESSION added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgcodecs.hpp missing IMWRITE_BMP_COMPRESSION (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: ImwriteBMPCompressionFlags enum should be added to imgcodecs.hpp (fixed version)
if grep -q 'enum ImwriteBMPCompressionFlags' modules/imgcodecs/include/opencv2/imgcodecs.hpp; then
    echo "PASS: imgcodecs.hpp has ImwriteBMPCompressionFlags enum added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgcodecs.hpp missing ImwriteBMPCompressionFlags enum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: BMP documentation about compression should be added (fixed version)
if grep -q 'OpenCV v4.13.0 or later use BI_BITFIELDS compression as default' modules/imgcodecs/include/opencv2/imgcodecs.hpp; then
    echo "PASS: imgcodecs.hpp has BMP compression documentation added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgcodecs.hpp missing BMP compression documentation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: grfmt_bmp.cpp should include logger header (fixed version)
if grep -q '#include "opencv2/core/utils/logger.hpp"' modules/imgcodecs/src/grfmt_bmp.cpp; then
    echo "PASS: grfmt_bmp.cpp has logger header include added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_bmp.cpp missing logger header include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: grfmt_bmp.cpp should have m_supported_encode_key (fixed version)
if grep -q 'm_supported_encode_key' modules/imgcodecs/src/grfmt_bmp.cpp; then
    echo "PASS: grfmt_bmp.cpp has m_supported_encode_key added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_bmp.cpp missing m_supported_encode_key (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: grfmt_bmp.cpp write function should use params parameter (fixed version)
if grep -q 'bool  BmpEncoder::write( const Mat& img, const std::vector<int>& params )' modules/imgcodecs/src/grfmt_bmp.cpp; then
    echo "PASS: grfmt_bmp.cpp write function uses params parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_bmp.cpp write function missing params parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: grfmt_bmp.cpp should have V5BITFIELDS header logic (fixed version)
if grep -q 'useV5BitFields' modules/imgcodecs/src/grfmt_bmp.cpp; then
    echo "PASS: grfmt_bmp.cpp has V5BITFIELDS header logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_bmp.cpp missing V5BITFIELDS header logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_grfmt.cpp should have Imgcodecs_bmp_compress test (fixed version)
if grep -q 'TEST_P(Imgcodecs_bmp_compress' modules/imgcodecs/test/test_grfmt.cpp; then
    echo "PASS: test_grfmt.cpp has Imgcodecs_bmp_compress test added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_grfmt.cpp missing Imgcodecs_bmp_compress test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_precomp.hpp should have PrintTo for ImwriteBMPCompressionFlags (fixed version)
if grep -q 'void PrintTo(const ImwriteBMPCompressionFlags&' modules/imgcodecs/test/test_precomp.hpp; then
    echo "PASS: test_precomp.hpp has PrintTo for ImwriteBMPCompressionFlags added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_precomp.hpp missing PrintTo for ImwriteBMPCompressionFlags (buggy version)" >&2
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
