#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_filter.cpp" "modules/imgproc/test/test_filter.cpp"

checks_passed=0
checks_failed=0

# PR #13844 adds AVX512 support for multi-channel (2, 3, 4) cv::integral with CV_64F output
# HEAD (507f8add1cd940fd803f375e3c2bfa9dee4c116a): Fixed version with template-based multi-channel support
# BASE (after bug.patch): Buggy version with only 3-channel support
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: Template-based IntegralCalculator should exist (fixed version)
if grep -q 'template<size_t num_channels> class IntegralCalculator' modules/imgproc/src/sumpixels.avx512_skx.cpp; then
    echo "PASS: Template IntegralCalculator exists in sumpixels.avx512_skx.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Template IntegralCalculator missing from sumpixels.avx512_skx.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Old IntegralCalculator_3Channel should NOT exist (fixed version removes it)
if grep -q 'class IntegralCalculator_3Channel' modules/imgproc/src/sumpixels.avx512_skx.cpp; then
    echo "FAIL: IntegralCalculator_3Channel still exists in sumpixels.avx512_skx.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: IntegralCalculator_3Channel removed from sumpixels.avx512_skx.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: Function should use calculate_integral_for_line (fixed version)
if grep -q 'calculate_integral_for_line' modules/imgproc/src/sumpixels.avx512_skx.cpp; then
    echo "PASS: calculate_integral_for_line exists in sumpixels.avx512_skx.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calculate_integral_for_line missing from sumpixels.avx512_skx.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Old integral_line_3channel_avx512 should NOT exist (fixed version removes it)
if grep -q 'integral_line_3channel_avx512' modules/imgproc/src/sumpixels.avx512_skx.cpp; then
    echo "FAIL: integral_line_3channel_avx512 still exists in sumpixels.avx512_skx.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: integral_line_3channel_avx512 removed from sumpixels.avx512_skx.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: Perf test should include CV_8UC2 (2-channel support in fixed version)
if grep -q 'CV_8UC1, CV_8UC2, CV_8UC3, CV_8UC4' modules/imgproc/perf/perf_integral.cpp; then
    echo "PASS: CV_8UC2 included in perf tests (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CV_8UC2 missing from perf tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: integral_sqsum should test CV_64F output depth (fixed version)
if grep -A 5 'PERF_TEST_P(Size_MatType_OutMatDepth, integral_sqsum' modules/imgproc/perf/perf_integral.cpp | grep -q 'CV_32S, CV_32F, CV_64F'; then
    echo "PASS: integral_sqsum tests CV_64F output depth (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: integral_sqsum missing CV_64F output depth (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: integral_sqsum_tilted should test CV_64F output depth (fixed version)
if grep -A 5 'PERF_TEST_P.*integral_sqsum_tilted' modules/imgproc/perf/perf_integral.cpp | grep -q 'CV_32S, CV_32F, CV_64F'; then
    echo "PASS: integral_sqsum_tilted tests CV_64F output depth (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: integral_sqsum_tilted missing CV_64F output depth (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: TODO comment should reference only 1-channel (fixed version adds 2,3,4 support)
if grep -q 'TODO: Add support for 1 channel input' modules/imgproc/src/sumpixels.avx512_skx.cpp; then
    echo "PASS: TODO updated to mention only 1-channel remaining (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: TODO still mentions 2,3,4 channels as unsupported (buggy version)" >&2
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
