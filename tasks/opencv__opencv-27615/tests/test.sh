#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_png.cpp" "modules/imgcodecs/test/test_png.cpp"

checks_passed=0
checks_failed=0

# Check 1: Imgcodecs_Png_ZLIBBUFFER_SIZE test typedef exists
if grep -q 'typedef testing::TestWithParam<int> Imgcodecs_Png_ZLIBBUFFER_SIZE;' modules/imgcodecs/test/test_png.cpp; then
    echo "PASS: test_png.cpp declares Imgcodecs_Png_ZLIBBUFFER_SIZE test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_png.cpp missing Imgcodecs_Png_ZLIBBUFFER_SIZE test typedef (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: encode_regression_27614 test exists
if grep -q 'TEST_P(Imgcodecs_Png_ZLIBBUFFER_SIZE, encode_regression_27614)' modules/imgcodecs/test/test_png.cpp; then
    echo "PASS: test_png.cpp contains encode_regression_27614 test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_png.cpp missing encode_regression_27614 test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: INSTANTIATE_TEST_CASE_P for Imgcodecs_Png_ZLIBBUFFER_SIZE exists
if grep -q 'INSTANTIATE_TEST_CASE_P(/\*nothing\*/, Imgcodecs_Png_ZLIBBUFFER_SIZE,' modules/imgcodecs/test/test_png.cpp; then
    echo "PASS: test_png.cpp instantiates Imgcodecs_Png_ZLIBBUFFER_SIZE test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_png.cpp missing Imgcodecs_Png_ZLIBBUFFER_SIZE test instantiation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: IMWRITE_PNG_ZLIBBUFFER_SIZE documentation is detailed (fixed version)
if grep -q 'IMWRITE_PNG_ZLIBBUFFER_SIZE = 20.*from 6 to 1048576' modules/imgcodecs/include/opencv2/imgcodecs.hpp; then
    echo "PASS: imgcodecs.hpp has detailed IMWRITE_PNG_ZLIBBUFFER_SIZE documentation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgcodecs.hpp has generic IMWRITE_PNG_ZLIBBUFFER_SIZE documentation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: png_set_compression_buffer_size has MIN/MAX validation in grfmt_png.cpp
if grep -q 'MIN(MAX(params\[i+1\],6), 1024\*1024)' modules/imgcodecs/src/grfmt_png.cpp; then
    echo "PASS: grfmt_png.cpp validates IMWRITE_PNG_ZLIBBUFFER_SIZE with MIN/MAX (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_png.cpp missing IMWRITE_PNG_ZLIBBUFFER_SIZE validation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: grfmt_spng.cpp includes logger header (for warning about unsupported feature)
if grep -q '#include <opencv2/core/utils/logger.hpp>' modules/imgcodecs/src/grfmt_spng.cpp; then
    echo "PASS: grfmt_spng.cpp includes logger header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_spng.cpp missing logger header include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: grfmt_spng.cpp warns about IMWRITE_PNG_ZLIBBUFFER_SIZE being unsupported
if grep -q 'if.*params\[i\] == IMWRITE_PNG_ZLIBBUFFER_SIZE' modules/imgcodecs/src/grfmt_spng.cpp; then
    echo "PASS: grfmt_spng.cpp checks for IMWRITE_PNG_ZLIBBUFFER_SIZE (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_spng.cpp missing IMWRITE_PNG_ZLIBBUFFER_SIZE check (buggy version)" >&2
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
