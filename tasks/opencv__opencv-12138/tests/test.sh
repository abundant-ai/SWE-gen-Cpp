#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_camera.cpp" "modules/videoio/test/test_camera.cpp"

checks_passed=0
checks_failed=0

# PR #12138: Add DirectShow crossbar input pin type selection support
# The fix adds CAP_CROSSBAR_INPIN_TYPE property and crossbar handling

# Check 1: CAP_CROSSBAR_INPIN_TYPE should be defined in videoio.hpp
if grep -q "CAP_CROSSBAR_INPIN_TYPE" modules/videoio/include/opencv2/videoio.hpp 2>/dev/null; then
    echo "PASS: CAP_CROSSBAR_INPIN_TYPE property exists in videoio.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CAP_CROSSBAR_INPIN_TYPE property should exist in videoio.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: PhysConn_Video_SerialDigital case (case 6) should exist in cap_dshow.cpp
if grep -q "PhysConn_Video_SerialDigital" modules/videoio/src/cap_dshow.cpp 2>/dev/null; then
    echo "PASS: PhysConn_Video_SerialDigital handling exists in cap_dshow.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PhysConn_Video_SerialDigital handling should exist in cap_dshow.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: PhysConn_Video_YRYBY case (case 5) should exist in cap_dshow.cpp
if grep -q "PhysConn_Video_YRYBY" modules/videoio/src/cap_dshow.cpp 2>/dev/null; then
    echo "PASS: PhysConn_Video_YRYBY handling exists in cap_dshow.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PhysConn_Video_YRYBY handling should exist in cap_dshow.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: CAP_CROSSBAR_INPIN_TYPE case handler should exist in setProperty
if grep -A 5 "case CAP_CROSSBAR_INPIN_TYPE:" modules/videoio/src/cap_dshow.cpp 2>/dev/null | grep -q "setupDevice"; then
    echo "PASS: CAP_CROSSBAR_INPIN_TYPE property handler exists in cap_dshow.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CAP_CROSSBAR_INPIN_TYPE property handler should exist in cap_dshow.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: rcSource rectangle update should exist in setSizeAndSubtype
if grep -q "pVih->rcSource.right" modules/videoio/src/cap_dshow.cpp 2>/dev/null && \
   grep -q "pVih->rcSource.bottom" modules/videoio/src/cap_dshow.cpp 2>/dev/null; then
    echo "PASS: rcSource rectangle update exists in cap_dshow.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: rcSource rectangle update should exist in cap_dshow.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test case for dshow_avermedia_capture should exist in test_camera.cpp
if grep -q "dshow_avermedia_capture" modules/videoio/test/test_camera.cpp 2>/dev/null; then
    echo "PASS: dshow_avermedia_capture test exists in test_camera.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dshow_avermedia_capture test should exist in test_camera.cpp" >&2
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
