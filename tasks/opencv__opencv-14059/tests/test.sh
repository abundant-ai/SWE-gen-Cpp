#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_grfmt.cpp" "modules/imgcodecs/test/test_grfmt.cpp"
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_read_write.cpp" "modules/imgcodecs/test/test_read_write.cpp"

checks_passed=0
checks_failed=0

# The fix adds Jasper codec enable/disable configuration support
# HEAD (43c68d18649): Has OPENCV_IO_FORCE_JASPER, OPENCV_IMGCODECS_ENABLE_JASPER_TESTS,
#                     isJasperEnabled function, initJasper calls, CV_Assert calls
# BASE (after bug.patch): Removes configuration support, forces Jasper always enabled
# FIXED (after fix.patch): Restores all HEAD features for Jasper configuration

# Check 1: modules/imgcodecs/CMakeLists.txt should have OPENCV_IO_FORCE_JASPER
if grep -q 'OPENCV_IO_FORCE_JASPER' modules/imgcodecs/CMakeLists.txt; then
    echo "PASS: modules/imgcodecs/CMakeLists.txt has OPENCV_IO_FORCE_JASPER (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/imgcodecs/CMakeLists.txt doesn't have OPENCV_IO_FORCE_JASPER (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: modules/imgcodecs/CMakeLists.txt should have OPENCV_IMGCODECS_ENABLE_JASPER_TESTS
if grep -q 'OPENCV_IMGCODECS_ENABLE_JASPER_TESTS' modules/imgcodecs/CMakeLists.txt; then
    echo "PASS: modules/imgcodecs/CMakeLists.txt has OPENCV_IMGCODECS_ENABLE_JASPER_TESTS (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/imgcodecs/CMakeLists.txt doesn't have OPENCV_IMGCODECS_ENABLE_JASPER_TESTS (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: modules/imgcodecs/src/grfmt_jpeg2000.cpp should have isJasperEnabled function
if grep -q 'static bool isJasperEnabled()' modules/imgcodecs/src/grfmt_jpeg2000.cpp; then
    echo "PASS: grfmt_jpeg2000.cpp has isJasperEnabled function (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg2000.cpp doesn't have isJasperEnabled function (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: modules/imgcodecs/src/grfmt_jpeg2000.cpp should have initJasper function
if grep -q 'static JasperInitializer& initJasper()' modules/imgcodecs/src/grfmt_jpeg2000.cpp; then
    echo "PASS: grfmt_jpeg2000.cpp has initJasper function (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg2000.cpp doesn't have initJasper function (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: modules/imgcodecs/src/grfmt_jpeg2000.cpp should have initJasper call in newDecoder
if grep -A 2 'ImageDecoder Jpeg2KDecoder::newDecoder()' modules/imgcodecs/src/grfmt_jpeg2000.cpp | grep -q 'initJasper()'; then
    echo "PASS: grfmt_jpeg2000.cpp Jpeg2KDecoder::newDecoder has initJasper call (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg2000.cpp Jpeg2KDecoder::newDecoder doesn't have initJasper call (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: modules/imgcodecs/src/grfmt_jpeg2000.cpp should have CV_Assert(isJasperEnabled) in close
if grep -A 3 'if( m_stream )' modules/imgcodecs/src/grfmt_jpeg2000.cpp | grep -q 'CV_Assert(isJasperEnabled())'; then
    echo "PASS: grfmt_jpeg2000.cpp close() has CV_Assert(isJasperEnabled()) (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg2000.cpp close() doesn't have CV_Assert(isJasperEnabled()) (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: modules/imgcodecs/src/grfmt_jpeg2000.cpp should have CV_Assert in readHeader
if grep -A 2 'bool  Jpeg2KDecoder::readHeader()' modules/imgcodecs/src/grfmt_jpeg2000.cpp | grep -q 'CV_Assert(isJasperEnabled())'; then
    echo "PASS: grfmt_jpeg2000.cpp readHeader has CV_Assert (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg2000.cpp readHeader doesn't have CV_Assert (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: modules/imgcodecs/src/grfmt_jpeg2000.cpp should include configuration.private.hpp
if grep -q '#include <opencv2/core/utils/configuration.private.hpp>' modules/imgcodecs/src/grfmt_jpeg2000.cpp; then
    echo "PASS: grfmt_jpeg2000.cpp includes configuration.private.hpp (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_jpeg2000.cpp doesn't include configuration.private.hpp (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: modules/imgcodecs/test/test_grfmt.cpp should use OPENCV_IMGCODECS_ENABLE_JASPER_TESTS
if grep -q 'defined(OPENCV_IMGCODECS_ENABLE_JASPER_TESTS)' modules/imgcodecs/test/test_grfmt.cpp; then
    echo "PASS: test_grfmt.cpp uses OPENCV_IMGCODECS_ENABLE_JASPER_TESTS (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_grfmt.cpp doesn't use OPENCV_IMGCODECS_ENABLE_JASPER_TESTS (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: modules/imgcodecs/test/test_read_write.cpp should use OPENCV_IMGCODECS_ENABLE_JASPER_TESTS
if grep -q 'defined(OPENCV_IMGCODECS_ENABLE_JASPER_TESTS)' modules/imgcodecs/test/test_read_write.cpp; then
    echo "PASS: test_read_write.cpp uses OPENCV_IMGCODECS_ENABLE_JASPER_TESTS (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_read_write.cpp doesn't use OPENCV_IMGCODECS_ENABLE_JASPER_TESTS (BASE version)" >&2
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
