#!/bin/bash

cd /app/src

# Apply fix.patch to get HEAD state for source code validation
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_video_io.cpp" "modules/videoio/test/test_video_io.cpp"

checks_passed=0
checks_failed=0

# PR #11748: Add exception mode to VideoCapture

# Check 1: videoio.hpp - setExceptionMode() method should be defined
if grep -q 'void setExceptionMode(bool enable)' modules/videoio/include/opencv2/videoio.hpp; then
    echo "PASS: setExceptionMode() method is defined"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setExceptionMode() method should be defined" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: videoio.hpp - getExceptionMode() method should be defined
if grep -q 'bool getExceptionMode()' modules/videoio/include/opencv2/videoio.hpp; then
    echo "PASS: getExceptionMode() method is defined"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: getExceptionMode() method should be defined" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: videoio.hpp - throwOnFail member variable should be defined
if grep -q 'bool throwOnFail' modules/videoio/include/opencv2/videoio.hpp; then
    echo "PASS: throwOnFail member variable is defined"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: throwOnFail member variable should be defined" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: cap.cpp - VideoCapture() constructor should initialize throwOnFail
if grep -q 'VideoCapture::VideoCapture() : throwOnFail(false)' modules/videoio/src/cap.cpp; then
    echo "PASS: Default constructor initializes throwOnFail"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Default constructor should initialize throwOnFail" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: cap.cpp - VideoCapture(filename) constructor should initialize throwOnFail
if grep -q 'VideoCapture::VideoCapture(const String& filename, int apiPreference) : throwOnFail(false)' modules/videoio/src/cap.cpp; then
    echo "PASS: Filename constructor initializes throwOnFail"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Filename constructor should initialize throwOnFail" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: cap.cpp - VideoCapture(index) constructor should initialize throwOnFail
if grep -q 'VideoCapture::VideoCapture(int index, int apiPreference) : throwOnFail(false)' modules/videoio/src/cap.cpp; then
    echo "PASS: Index constructor initializes throwOnFail"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Index constructor should initialize throwOnFail" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: cap.cpp - open(filename) should throw when throwOnFail is enabled
if grep -q 'if(throwOnFail && apiPreference != CAP_ANY) throw' modules/videoio/src/cap.cpp; then
    echo "PASS: open() re-throws exceptions when throwOnFail is enabled"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: open() should re-throw exceptions when throwOnFail is enabled" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: cap.cpp - open(filename) should throw CV_Error when file doesn't exist and throwOnFail
if grep -q "if (throwOnFail)" modules/videoio/src/cap.cpp && grep -q "CV_Error_.*could not open" modules/videoio/src/cap.cpp; then
    echo "PASS: open() throws CV_Error when file doesn't exist and throwOnFail is enabled"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: open() should throw CV_Error when file doesn't exist and throwOnFail is enabled" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: cap.cpp - grab() should throw when throwOnFail is enabled
if grep -A 6 'bool VideoCapture::grab()' modules/videoio/src/cap.cpp | grep -q 'if (!ret && throwOnFail)'; then
    echo "PASS: grab() throws when throwOnFail is enabled"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grab() should throw when throwOnFail is enabled" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: cap.cpp - retrieve() should throw when throwOnFail is enabled
if grep -A 8 'bool VideoCapture::retrieve' modules/videoio/src/cap.cpp | grep -q 'if (!ret && throwOnFail)'; then
    echo "PASS: retrieve() throws when throwOnFail is enabled"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: retrieve() should throw when throwOnFail is enabled" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: cap.cpp - set() should throw when throwOnFail is enabled
if grep -A 6 'bool VideoCapture::set' modules/videoio/src/cap.cpp | grep -q 'if (!ret && throwOnFail)'; then
    echo "PASS: set() throws when throwOnFail is enabled"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: set() should throw when throwOnFail is enabled" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_video_io.cpp - exception test should exist
if grep -q 'TEST(Videoio, exceptions)' modules/videoio/test/test_video_io.cpp; then
    echo "PASS: Exception test case exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Exception test case should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_video_io.cpp - test should verify setExceptionMode
if grep -q 'cap.setExceptionMode(true)' modules/videoio/test/test_video_io.cpp; then
    echo "PASS: Test verifies setExceptionMode()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify setExceptionMode()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: test_video_io.cpp - test should verify grab() throws
if grep -q 'EXPECT_THROW(cap.grab(), Exception)' modules/videoio/test/test_video_io.cpp; then
    echo "PASS: Test verifies grab() throws exception"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify grab() throws exception" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: test_video_io.cpp - test should verify retrieve() throws
if grep -q 'EXPECT_THROW(cap.retrieve' modules/videoio/test/test_video_io.cpp; then
    echo "PASS: Test verifies retrieve() throws exception"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify retrieve() throws exception" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: test_video_io.cpp - test should verify set() throws
if grep -q 'EXPECT_THROW(cap.set' modules/videoio/test/test_video_io.cpp; then
    echo "PASS: Test verifies set() throws exception"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify set() throws exception" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: test_video_io.cpp - test should verify open() throws
if grep -q 'EXPECT_THROW(cap.open' modules/videoio/test/test_video_io.cpp; then
    echo "PASS: Test verifies open() throws exception"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should verify open() throws exception" >&2
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
