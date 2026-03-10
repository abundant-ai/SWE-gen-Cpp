#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/misc/java/test"
cp "/tests/modules/calib3d/misc/java/test/Calib3dTest.java" "modules/calib3d/misc/java/test/Calib3dTest.java"
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_undistort.cpp" "modules/calib3d/test/test_undistort.cpp"
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_undistort_badarg.cpp" "modules/calib3d/test/test_undistort_badarg.cpp"
mkdir -p "modules/imgproc/misc/java/test"
cp "/tests/modules/imgproc/misc/java/test/ImgprocTest.java" "modules/imgproc/misc/java/test/ImgprocTest.java"
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_imgwarp.cpp" "modules/imgproc/test/test_imgwarp.cpp"

checks_passed=0
checks_failed=0

# PR #12728: Move undistortion APIs from imgproc to calib3d and fix Java bindings
# For harbor testing:
# - HEAD (8f1f4273a2484d3191afce1ce5aed9d6ac5cd428): Fixed version WITH undistort in calib3d
# - BASE (after bug.patch): Buggy version WITH undistort in imgproc (wrong module)
# - FIXED (after oracle applies fix): Back to fixed version WITH undistort in calib3d

# Check 1: calib3d.hpp SHOULD have undistort function (fixed version has it)
if grep -q 'CV_EXPORTS_W void undistort' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has undistort function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing undistort function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: calib3d.hpp SHOULD have initUndistortRectifyMap function (fixed version has it)
if grep -q 'CV_EXPORTS_W void initUndistortRectifyMap' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has initUndistortRectifyMap function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing initUndistortRectifyMap function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: imgproc.hpp SHOULD NOT have undistort function (fixed version doesn't have it)
if grep -q 'CV_EXPORTS_W void undistort' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "FAIL: imgproc.hpp still has undistort function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: imgproc.hpp doesn't have undistort function - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: imgproc.hpp SHOULD NOT have initUndistortRectifyMap (fixed version doesn't have it)
if grep -q 'CV_EXPORTS_W void initUndistortRectifyMap' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "FAIL: imgproc.hpp still has initUndistortRectifyMap - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: imgproc.hpp doesn't have initUndistortRectifyMap - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: undistort.cpp SHOULD be in calib3d/src (fixed version has it there)
if [ -f "modules/calib3d/src/undistort.cpp" ]; then
    echo "PASS: undistort.cpp is in calib3d/src - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: undistort.cpp missing from calib3d/src - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: undistort.cpp in calib3d SHOULD include distortion_model.hpp (fixed version has it)
if grep -q '#include "distortion_model.hpp"' modules/calib3d/src/undistort.cpp 2>/dev/null; then
    echo "PASS: undistort.cpp includes distortion_model.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: undistort.cpp missing distortion_model.hpp include - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: calib3d_c.h SHOULD have cvUndistortPoints C API (fixed version has it)
if grep -q 'CVAPI(void) cvUndistortPoints' modules/calib3d/include/opencv2/calib3d/calib3d_c.h; then
    echo "PASS: calib3d_c.h has cvUndistortPoints - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d_c.h missing cvUndistortPoints - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: imgproc_c.h SHOULD NOT have cvUndistortPoints (fixed version doesn't have it)
if grep -q 'CVAPI(void) cvUndistortPoints' modules/imgproc/include/opencv2/imgproc/imgproc_c.h; then
    echo "FAIL: imgproc_c.h still has cvUndistortPoints - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: imgproc_c.h doesn't have cvUndistortPoints - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 9: Calib3dTest.java SHOULD have undistortPoints test (fixed version has it)
if grep -q 'testUndistortPoints' modules/calib3d/misc/java/test/Calib3dTest.java; then
    echo "PASS: Calib3dTest.java has undistortPoints test - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Calib3dTest.java missing undistortPoints test - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: ImgprocTest.java SHOULD NOT have undistortPoints test (fixed version doesn't have it)
if grep -q 'testUndistortPoints' modules/imgproc/misc/java/test/ImgprocTest.java; then
    echo "FAIL: ImgprocTest.java still has undistortPoints test - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: ImgprocTest.java doesn't have undistortPoints test - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 11: test_undistort.cpp SHOULD be in calib3d/test (fixed version has it there)
if [ -f "modules/calib3d/test/test_undistort.cpp" ]; then
    echo "PASS: test_undistort.cpp is in calib3d/test - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_undistort.cpp missing from calib3d/test - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: distortion_model.hpp SHOULD be in calib3d/src (fixed version has it there)
if [ -f "modules/calib3d/src/distortion_model.hpp" ]; then
    echo "PASS: distortion_model.hpp is in calib3d/src - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: distortion_model.hpp missing from calib3d/src - buggy version" >&2
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
