#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_cameracalibration.cpp" "modules/calib3d/test/test_cameracalibration.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11703: Separate C API wrappers from calibinit.cpp into calib3d_c_api.cpp

# Check 1: calib3d_c_api.cpp should exist
if [ -f "modules/calib3d/src/calib3d_c_api.cpp" ]; then
    echo "PASS: calib3d_c_api.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d_c_api.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: calib3d_c_api.cpp should contain cvDrawChessboardCorners
if grep -q 'cvDrawChessboardCorners' modules/calib3d/src/calib3d_c_api.cpp 2>/dev/null; then
    echo "PASS: calib3d_c_api.cpp contains cvDrawChessboardCorners"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d_c_api.cpp should contain cvDrawChessboardCorners" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: calib3d_c_api.cpp should contain cvFindChessboardCorners
if grep -q 'cvFindChessboardCorners' modules/calib3d/src/calib3d_c_api.cpp 2>/dev/null; then
    echo "PASS: calib3d_c_api.cpp contains cvFindChessboardCorners"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d_c_api.cpp should contain cvFindChessboardCorners" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: calib3d_c_api.cpp should include calib3d_c.h
if grep -q '#include "opencv2/calib3d/calib3d_c.h"' modules/calib3d/src/calib3d_c_api.cpp 2>/dev/null; then
    echo "PASS: calib3d_c_api.cpp includes calib3d_c.h"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d_c_api.cpp should include calib3d_c.h" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: calibinit.cpp should NOT include imgproc_c.h at the top (modernized)
# The include was moved inside a conditional block, not at the top with other includes
if ! head -80 modules/calib3d/src/calibinit.cpp | grep -q '#include "opencv2/imgproc/imgproc_c.h"'; then
    echo "PASS: calibinit.cpp does not include imgproc_c.h at the top"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibinit.cpp should not include imgproc_c.h at the top (modernized)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: calibinit.cpp should NOT include calib3d_c.h (modernized)
if ! grep -q '#include "opencv2/calib3d/calib3d_c.h"' modules/calib3d/src/calibinit.cpp; then
    echo "PASS: calibinit.cpp does not include calib3d_c.h"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibinit.cpp should not include calib3d_c.h (modernized)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: calibinit.cpp should use namespace cv (modernized style)
if grep -q '^namespace cv {' modules/calib3d/src/calibinit.cpp; then
    echo "PASS: calibinit.cpp uses namespace cv"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibinit.cpp should use namespace cv" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: calibinit.cpp should use DPRINTF instead of PRINTF (modernized debug macro)
if grep -q '#define DPRINTF' modules/calib3d/src/calibinit.cpp; then
    echo "PASS: calibinit.cpp uses DPRINTF macro"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibinit.cpp should use DPRINTF macro" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: calibinit.cpp should use DEBUG_CHESSBOARD_TIMEOUT (modernized debug)
if grep -q 'DEBUG_CHESSBOARD_TIMEOUT' modules/calib3d/src/calibinit.cpp; then
    echo "PASS: calibinit.cpp defines DEBUG_CHESSBOARD_TIMEOUT"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibinit.cpp should define DEBUG_CHESSBOARD_TIMEOUT" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: calibinit.cpp should include stack header (modernized)
if grep -q '#include <stack>' modules/calib3d/src/calibinit.cpp; then
    echo "PASS: calibinit.cpp includes <stack>"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibinit.cpp should include <stack>" >&2
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
