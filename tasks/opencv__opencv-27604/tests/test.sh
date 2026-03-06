#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_io.cpp" "modules/core/test/test_io.cpp"
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_exif.cpp" "modules/imgcodecs/test/test_exif.cpp"
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_gdal.cpp" "modules/imgcodecs/test/test_gdal.cpp"
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_png.cpp" "modules/imgcodecs/test/test_png.cpp"
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_connectedcomponents.cpp" "modules/imgproc/test/test_connectedcomponents.cpp"

checks_passed=0
checks_failed=0

# Check 1: ARM64 NEON rounding for double in fast_math.hpp (fixed version has vcvtn_s64_f64)
if grep -q 'vcvtn_s64_f64' modules/core/include/opencv2/core/fast_math.hpp; then
    echo "PASS: fast_math.hpp contains ARM64 NEON rounding for double (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: fast_math.hpp missing ARM64 NEON rounding for double (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: ARM64 NEON rounding for float in fast_math.hpp (fixed version has vcvtn_s32_f32)
if grep -q 'vcvtn_s32_f32' modules/core/include/opencv2/core/fast_math.hpp; then
    echo "PASS: fast_math.hpp contains ARM64 NEON rounding for float (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: fast_math.hpp missing ARM64 NEON rounding for float (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: JSON key backslash handling in persistence_json.cpp (fixed version handles backslashes)
if grep -q 'if (\*ptr == .\\\\.)' modules/core/src/persistence_json.cpp; then
    echo "PASS: persistence_json.cpp handles backslash in JSON keys (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: persistence_json.cpp missing backslash handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Test for JSON key backslash exists in test_io.cpp
if grep -q 'TEST(Core_InputOutput, FileStorage_json_key_backslash)' modules/core/test/test_io.cpp; then
    echo "PASS: test_io.cpp contains FileStorage_json_key_backslash test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_io.cpp missing FileStorage_json_key_backslash test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: JPEG decoder saves APP2 markers (fixed version)
if grep -q 'jpeg_save_markers(&state->cinfo, APP2, 0xffff);' modules/imgcodecs/src/grfmt_jpeg.cpp; then
    echo "PASS: grfmt_jpeg.cpp saves APP2 markers for ICC profile (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg.cpp does not save APP2 markers (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: JPEG decoder parses XMP metadata (fixed version)
if grep -q 'IMAGE_METADATA_XMP' modules/imgcodecs/src/grfmt_jpeg.cpp; then
    echo "PASS: grfmt_jpeg.cpp handles XMP metadata (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg.cpp missing XMP metadata handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: JPEG encoder supports XMP metadata (fixed version)
if grep -q 'IMAGE_METADATA_XMP.*true' modules/imgcodecs/src/grfmt_jpeg.cpp; then
    echo "PASS: grfmt_jpeg.cpp encoder supports XMP metadata (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg.cpp encoder does not support XMP (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: JPEG encoder supports ICCP metadata (fixed version)
if grep -q 'IMAGE_METADATA_ICCP.*true' modules/imgcodecs/src/grfmt_jpeg.cpp; then
    echo "PASS: grfmt_jpeg.cpp encoder supports ICCP metadata (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg.cpp encoder does not support ICCP (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: PNG handles old libpng versions for iCCP (fixed version has version check)
if grep -q 'PNG_LIBPNG_VER_MAJOR\*10000.*PNG_LIBPNG_VER_MINOR' modules/imgcodecs/src/grfmt_png.cpp; then
    echo "PASS: grfmt_png.cpp has libpng version check for iCCP (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_png.cpp missing libpng version check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: PNG uses PNG_eXIf_SUPPORTED guard (fixed version)
if grep -q '#ifdef PNG_eXIf_SUPPORTED' modules/imgcodecs/src/grfmt_png.cpp; then
    echo "PASS: grfmt_png.cpp guards EXIF with PNG_eXIf_SUPPORTED (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_png.cpp missing PNG_eXIf_SUPPORTED guard (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: PNG uses char* for iccp_profile_name (fixed version uses char array)
if grep -q 'char iccp_profile_name\[\].*ICC Profile' modules/imgcodecs/src/grfmt_png.cpp; then
    echo "PASS: grfmt_png.cpp uses char array for ICC profile name (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_png.cpp uses const char* for ICC profile name (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: EXIF test uses ASSERT_GE instead of EXPECT_GE (fixed version)
if grep -q 'ASSERT_GE(read_metadata_types.size(), 1u);' modules/imgcodecs/test/test_exif.cpp; then
    echo "PASS: test_exif.cpp uses ASSERT_GE for metadata check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_exif.cpp uses EXPECT_GE for metadata check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: EXIF test includes XMP and ICCP size checks (fixed version)
if grep -q 'expected_xmp_size' modules/imgcodecs/test/test_exif.cpp; then
    echo "PASS: test_exif.cpp validates XMP size (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_exif.cpp missing XMP size validation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: PNG test validates imencode with ZLIBBUFFER_SIZE parameter (fixed version)
if grep -q 'ASSERT_TRUE(status);' modules/imgcodecs/test/test_png.cpp; then
    echo "PASS: test_png.cpp validates imencode status (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_png.cpp missing status validation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: Connected components has overflow check function (fixed version)
if grep -q 'checkLabelTypeOverflowBeforeIncrement' modules/imgproc/src/connectedcomponents.cpp; then
    echo "PASS: connectedcomponents.cpp has overflow check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: connectedcomponents.cpp missing overflow check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: Connected components test for regression 27568 exists (fixed version)
if grep -q 'TEST(Imgproc_ConnectedComponents, regression_27568)' modules/imgproc/test/test_connectedcomponents.cpp; then
    echo "PASS: test_connectedcomponents.cpp has regression_27568 test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_connectedcomponents.cpp missing regression_27568 test (buggy version)" >&2
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
