#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_chesscorners.cpp" "modules/calib3d/test/test_chesscorners.cpp"

checks_passed=0
checks_failed=0

# PR #12147: Implement findChessboardCornersSB function
# The fix adds a new high-performance chessboard corner detection function

# Check 1: Function declaration should exist in calib3d.hpp
if grep -q 'CV_EXPORTS_W bool findChessboardCornersSB' modules/calib3d/include/opencv2/calib3d.hpp 2>/dev/null; then
    echo "PASS: findChessboardCornersSB declaration exists in calib3d.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findChessboardCornersSB declaration should exist in calib3d.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: New implementation file chessboard.cpp should exist
if [ -f "modules/calib3d/src/chessboard.cpp" ]; then
    echo "PASS: chessboard.cpp implementation file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: chessboard.cpp implementation file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: New header file chessboard.hpp should exist
if [ -f "modules/calib3d/src/chessboard.hpp" ]; then
    echo "PASS: chessboard.hpp header file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: chessboard.hpp header file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Function implementation should exist in chessboard.cpp
if grep -q 'bool cv::findChessboardCornersSB' modules/calib3d/src/chessboard.cpp 2>/dev/null; then
    echo "PASS: findChessboardCornersSB implementation exists in chessboard.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findChessboardCornersSB implementation should exist in chessboard.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: CMakeLists.txt should include opencv_flann dependency
if grep -q 'opencv_flann' modules/calib3d/CMakeLists.txt 2>/dev/null; then
    echo "PASS: CMakeLists.txt includes opencv_flann dependency"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should include opencv_flann dependency" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test file should have CHESSBOARD_SB pattern support
if grep -q 'CHESSBOARD_SB' modules/calib3d/test/test_chesscorners.cpp 2>/dev/null; then
    echo "PASS: Test file includes CHESSBOARD_SB pattern"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test file should include CHESSBOARD_SB pattern" >&2
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
