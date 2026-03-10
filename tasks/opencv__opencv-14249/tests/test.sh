#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# The fix adds comprehensive error handling with CV_TIFF_CHECK_CALL macros and proper error handlers.
# We validate by checking source files for the fixed state.

# Check 1: grfmt_tiff.cpp should include logger.hpp (fixed version)
if grep -q "#include <opencv2/core/utils/logger.hpp>" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp includes logger.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp missing logger.hpp include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: grfmt_tiff.cpp should have CV_TIFF_CHECK_CALL macro (fixed version)
if grep -q "#define CV_TIFF_CHECK_CALL(call)" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp has CV_TIFF_CHECK_CALL macro (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp missing CV_TIFF_CHECK_CALL macro (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: grfmt_tiff.cpp should have cv_tiffCloseHandle function (fixed version)
if grep -q "static void cv_tiffCloseHandle(void\* handle)" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp has cv_tiffCloseHandle function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp missing cv_tiffCloseHandle function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: grfmt_tiff.cpp should have cv_tiffErrorHandler function (fixed version)
if grep -q "static void cv_tiffErrorHandler(const char\* module, const char\* fmt, va_list ap)" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp has cv_tiffErrorHandler function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp missing cv_tiffErrorHandler function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: grfmt_tiff.cpp should NOT have GrFmtSilentTIFFErrorHandler (old buggy version)
if ! grep -q "static void GrFmtSilentTIFFErrorHandler" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp does not have GrFmtSilentTIFFErrorHandler (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp has GrFmtSilentTIFFErrorHandler (buggy version)" >&2
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
