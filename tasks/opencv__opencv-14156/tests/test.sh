#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state with fixed versions)
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_dynamic.cpp" "modules/videoio/test/test_dynamic.cpp"
cp "/tests/modules/videoio/test/test_mfx.cpp" "modules/videoio/test/test_mfx.cpp"
cp "/tests/modules/videoio/test/test_video_io.cpp" "modules/videoio/test/test_video_io.cpp"

checks_passed=0
checks_failed=0

# The fix adds input parameter validation and error handling to video writers
# HEAD (d7c4eaa8de): Has std::string parameters, validation code, and comprehensive tests
# BASE (after bug.patch): Removes validation, changes to const char*, removes write_invalid test
# FIXED (after fix.patch): Restores std::string parameters, validation, and error handling
# Test files from /tests are copied to verify test changes

# Check 1: cap_avfoundation_mac.mm should use std::string in HEAD version
if grep -q 'CvVideoWriter_AVFoundation(const std::string &filename' modules/videoio/src/cap_avfoundation_mac.mm; then
    echo "PASS: Constructor uses std::string (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Constructor doesn't use std::string (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: cap_avfoundation_mac.mm should have isOpened method in HEAD version
if grep -q 'bool isOpened() const' modules/videoio/src/cap_avfoundation_mac.mm; then
    echo "PASS: isOpened() method present (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: isOpened() method missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: cap_avfoundation_mac.mm should have is_good member in HEAD version
if grep -q 'bool is_good;' modules/videoio/src/cap_avfoundation_mac.mm; then
    echo "PASS: is_good member present (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: is_good member missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: cap_gstreamer.cpp open should use std::string in HEAD version
if grep -q 'bool open(const std::string &filename' modules/videoio/src/cap_gstreamer.cpp; then
    echo "PASS: GStreamer open() uses std::string (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: GStreamer open() doesn't use std::string (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: cap_mfx_writer.cpp should have fps <= 0 validation in HEAD version
if grep -q 'if (fps <= 0)' modules/videoio/src/cap_mfx_writer.cpp; then
    echo "PASS: FPS validation present (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FPS validation missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_dynamic.cpp should have write_invalid test in HEAD version
if grep -q 'TEST(videoio_dynamic, write_invalid)' modules/videoio/test/test_dynamic.cpp; then
    echo "PASS: write_invalid test present (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: write_invalid test missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_mfx.cpp should have ASSERT_NO_THROW for zero FPS in HEAD version
if grep -q 'ASSERT_NO_THROW(res = writer.open(filename, CAP_INTEL_MFX, VideoWriter::fourcc' modules/videoio/test/test_mfx.cpp; then
    echo "PASS: Test expects no exception for zero FPS (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test expects exception for zero FPS (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_video_io.cpp should NOT have 3gp format tests in HEAD version
if ! grep -q 'makeParam("3gp", "H264"' modules/videoio/test/test_video_io.cpp; then
    echo "PASS: 3gp format tests not added yet (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: 3gp format tests present (BASE version)" >&2
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
