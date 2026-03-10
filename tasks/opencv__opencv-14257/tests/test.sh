#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# The fix includes several improvements:
# 1) Restores macOS-specific dylib handling for CPU extensions (DNN/OpenVINO)
# 2) Improves TIFF error handling with proper macros and logger integration
# 3) Modernizes TIFF decoder to use better resource management
# We validate by checking source files for the fixed state

# Check 1: DNN op_inf_engine.cpp SHOULD have Apple dylib handling (fixed version adds it back)
if grep -q '#elif defined(__APPLE__)' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp has Apple dylib handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp missing Apple dylib handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: grfmt_tiff.cpp should have CV_TIFF_CHECK_CALL macro (fixed version)
if grep -q "#define CV_TIFF_CHECK_CALL" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp has CV_TIFF_CHECK_CALL macro (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp missing CV_TIFF_CHECK_CALL macro (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: grfmt_tiff.cpp should include logger.hpp (fixed version)
if grep -q "#include <opencv2/core/utils/logger.hpp>" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp includes logger.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp does not include logger.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: grfmt_tiff.cpp should have cv_tiffCloseHandle function (fixed version uses modern approach)
if grep -q "static void cv_tiffCloseHandle" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp has cv_tiffCloseHandle function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp missing cv_tiffCloseHandle function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: grfmt_tiff.cpp should have cv_tiffErrorHandler function (fixed version)
if grep -q "static void cv_tiffErrorHandler" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp has cv_tiffErrorHandler function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp missing cv_tiffErrorHandler function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: grfmt_tiff.cpp should NOT have old grfmt_tiff_err_handler_init (buggy version pattern)
if ! grep -q "static int grfmt_tiff_err_handler_init = 0" modules/imgcodecs/src/grfmt_tiff.cpp; then
    echo "PASS: grfmt_tiff.cpp does not have old error handler init pattern (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_tiff.cpp has old error handler init pattern (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: grfmt_tiff.cpp TiffDecoder should NOT have m_tif = 0 in constructor (fixed uses modern approach)
if ! grep -A 15 "TiffDecoder::TiffDecoder()" modules/imgcodecs/src/grfmt_tiff.cpp | grep -q "m_tif = 0"; then
    echo "PASS: TiffDecoder constructor does not have m_tif = 0 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: TiffDecoder constructor has m_tif = 0 (buggy version)" >&2
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
