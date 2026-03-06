#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/3d/test"
cp "/tests/modules/3d/test/test_filter_homography_decomp.cpp" "modules/3d/test/test_filter_homography_decomp.cpp"

checks_passed=0
checks_failed=0

# Check 1: CV_8S/CV_Bool mask types added to homography_decomp.cpp assertion (fixed version)
if grep -q 'CV_Assert(_pointsMask.empty() || _pointsMask.type() == CV_8U || _pointsMask.type() == CV_8S || _pointsMask.type() == CV_Bool);' modules/3d/src/homography_decomp.cpp; then
    echo "PASS: homography_decomp.cpp has CV_8S/CV_Bool support (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: homography_decomp.cpp uses CV_8U only assertion (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: CV_8S/CV_Bool mask types added to levmarq.cpp assertion (fixed version)
if grep -q 'CV_Assert(mask_.depth() == CV_8U || mask_.depth() == CV_8S || mask_.depth() == CV_Bool);' modules/3d/src/levmarq.cpp; then
    echo "PASS: levmarq.cpp has CV_8S/CV_Bool support (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: levmarq.cpp uses CV_8U only assertion (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: CV_8S/CV_Bool mask types added to ptsetreg.cpp assertion (fixed version)
if grep -q 'CV_Assert( err.isContinuous() && err.type() == CV_32F && mask.isContinuous() && (mask.type() == CV_8S || mask.type() == CV_8U || mask.type() == CV_Bool));' modules/3d/src/ptsetreg.cpp; then
    echo "PASS: ptsetreg.cpp has CV_8S/CV_Bool support (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ptsetreg.cpp uses CV_8U only assertion (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: CV_8SC1/CV_BoolC1 mask types added to rendering.cpp assertion (fixed version)
if grep -q 'CV_Assert(validMask.type() == CV_8UC1 || validMask.type() == CV_8SC1 || validMask.type() == CV_BoolC1);' modules/3d/src/rendering.cpp; then
    echo "PASS: rendering.cpp has CV_8SC1/CV_BoolC1 support (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: rendering.cpp uses CV_8UC1 only assertion (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: CV_8S/CV_Bool mask types added to depth_to_3d.hpp check (fixed version)
if grep -q 'if ((mask.depth() != CV_8S) && (mask.depth() != CV_8U) && (mask.depth() != CV_Bool))' modules/3d/src/rgbd/depth_to_3d.hpp; then
    echo "PASS: depth_to_3d.hpp has CV_8S/CV_Bool support (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: depth_to_3d.hpp checks CV_8U only (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: CV_8SC1/CV_BoolC1 mask types added to odometry.cpp assertion (fixed version)
if grep -q 'CV_Assert(mask.type() == CV_8UC1 || mask.type() == CV_8SC1 || mask.type() == CV_BoolC1);' modules/3d/src/rgbd/odometry.cpp; then
    echo "PASS: odometry.cpp has CV_8SC1/CV_BoolC1 support (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: odometry.cpp uses CV_8UC1 only assertion (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: CV_8SC1/CV_BoolC1 mask types added to odometry_functions.cpp (fixed version)
# There are two locations in this file that need the fix
if grep -c 'CV_Assert(mask.type() == CV_8UC1 || mask.type() == CV_8SC1 || mask.type() == CV_BoolC1);' modules/3d/src/rgbd/odometry_functions.cpp | grep -q '^2$'; then
    echo "PASS: odometry_functions.cpp has CV_8SC1/CV_BoolC1 support in both locations (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: odometry_functions.cpp missing CV_8SC1/CV_BoolC1 support in one or both locations (buggy version)" >&2
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
