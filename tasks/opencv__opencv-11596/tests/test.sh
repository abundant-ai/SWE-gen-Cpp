#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_ffmpeg.cpp" "modules/videoio/test/test_ffmpeg.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11596: Runtime backend priority control for VideoIO

# Check 1: CMakeLists.txt should include videoio_registry.cpp and videoio_c.cpp
if grep -q 'videoio_registry.cpp' modules/videoio/CMakeLists.txt && grep -q 'videoio_c.cpp' modules/videoio/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt includes videoio_registry.cpp and videoio_c.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should include videoio_registry.cpp and videoio_c.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: videoio_registry.cpp should handle OPENCV_VIDEOIO_PRIORITY_<BACKEND> environment variables
if grep -q 'OPENCV_VIDEOIO_PRIORITY_' modules/videoio/src/videoio_registry.cpp; then
    echo "PASS: videoio_registry.cpp handles per-backend priority environment variables"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should handle OPENCV_VIDEOIO_PRIORITY_<BACKEND> variables" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: videoio_registry.cpp should handle OPENCV_VIDEOIO_PRIORITY_LIST environment variable
if grep -q 'OPENCV_VIDEOIO_PRIORITY_LIST' modules/videoio/src/videoio_registry.cpp; then
    echo "PASS: videoio_registry.cpp handles OPENCV_VIDEOIO_PRIORITY_LIST"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should handle OPENCV_VIDEOIO_PRIORITY_LIST" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: videoio_registry.cpp should use getConfigurationParameterSizeT for reading priority
if grep -q 'getConfigurationParameterSizeT' modules/videoio/src/videoio_registry.cpp; then
    echo "PASS: videoio_registry.cpp uses getConfigurationParameterSizeT for priority"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should use getConfigurationParameterSizeT" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: videoio_registry.cpp should disable backends when priority is 0
if grep -A8 'if (param_priority > 0)' modules/videoio/src/videoio_registry.cpp | grep -q 'Disable backend'; then
    echo "PASS: videoio_registry.cpp disables backends when priority is 0"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should disable backends when priority is 0" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: cap.cpp should include videoio_registry.hpp
if grep -q 'videoio_registry.hpp' modules/videoio/src/cap.cpp; then
    echo "PASS: cap.cpp includes videoio_registry.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cap.cpp should include videoio_registry.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: videoio_c.cpp should exist (was removed in bug.patch)
if [ -f modules/videoio/src/videoio_c.cpp ]; then
    echo "PASS: videoio_c.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_c.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: videoio_registry.cpp should exist (was removed in bug.patch)
if [ -f modules/videoio/src/videoio_registry.cpp ]; then
    echo "PASS: videoio_registry.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should exist" >&2
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
