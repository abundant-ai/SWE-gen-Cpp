#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_png.cpp" "modules/imgcodecs/test/test_png.cpp"

checks_passed=0
checks_failed=0

# Check 1: IMWRITE_PNG_ZLIBBUFFER_SIZE should be added to imgcodecs.hpp (fixed version)
if grep -q 'IMWRITE_PNG_ZLIBBUFFER_SIZE' modules/imgcodecs/include/opencv2/imgcodecs.hpp; then
    echo "PASS: imgcodecs.hpp has IMWRITE_PNG_ZLIBBUFFER_SIZE added (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgcodecs.hpp missing IMWRITE_PNG_ZLIBBUFFER_SIZE (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: grfmt_png.cpp should handle IMWRITE_PNG_ZLIBBUFFER_SIZE parameter (fixed version)
if grep -q 'IMWRITE_PNG_ZLIBBUFFER_SIZE' modules/imgcodecs/src/grfmt_png.cpp; then
    echo "PASS: grfmt_png.cpp handles IMWRITE_PNG_ZLIBBUFFER_SIZE parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_png.cpp missing IMWRITE_PNG_ZLIBBUFFER_SIZE handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: grfmt_png.cpp should use switch statement for parameter handling (fixed version)
if grep -q 'switch (params\[i\])' modules/imgcodecs/src/grfmt_png.cpp; then
    echo "PASS: grfmt_png.cpp uses switch statement for parameter handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_png.cpp missing switch statement for parameter handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: grfmt_png.cpp should call png_set_compression_buffer_size (fixed version)
if grep -q 'png_set_compression_buffer_size' modules/imgcodecs/src/grfmt_png.cpp; then
    echo "PASS: grfmt_png.cpp calls png_set_compression_buffer_size (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_png.cpp missing png_set_compression_buffer_size call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_png.cpp should test imencode with IMWRITE_PNG_ZLIBBUFFER_SIZE (fixed version)
if grep -q 'IMWRITE_PNG_ZLIBBUFFER_SIZE' modules/imgcodecs/test/test_png.cpp; then
    echo "PASS: test_png.cpp tests imencode with IMWRITE_PNG_ZLIBBUFFER_SIZE (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_png.cpp missing IMWRITE_PNG_ZLIBBUFFER_SIZE test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_png.cpp should test with INT_MAX buffer size (fixed version)
if grep -q 'INT_MAX' modules/imgcodecs/test/test_png.cpp; then
    echo "PASS: test_png.cpp tests with INT_MAX buffer size (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_png.cpp missing INT_MAX buffer size test (buggy version)" >&2
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
