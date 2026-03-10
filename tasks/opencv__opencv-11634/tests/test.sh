#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_stereomatching.cpp" "modules/calib3d/test/test_stereomatching.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11634: Fix empty matrix handling in various OpenCV modules

# Check 1: mat.inl.hpp should allow empty matrices in assignment operator
if grep -q 'CV_Assert(DataType<_Tp>::channels == m.channels() || m.empty())' modules/core/include/opencv2/core/mat.inl.hpp; then
    echo "PASS: mat.inl.hpp allows empty matrices in assignment operator"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.inl.hpp should allow empty matrices in assignment operator" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: arithm.cpp should handle empty matrices in compare function
if grep -q 'if(_src1.empty() && _src2.empty())' modules/core/src/arithm.cpp; then
    echo "PASS: arithm.cpp handles empty matrices in compare function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp should handle empty matrices in compare function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: convert.cpp should handle empty matrices in convertTo
if grep -A3 'CV_INSTRUMENT_REGION()' modules/core/src/convert.cpp | grep -q 'if( empty() )'; then
    echo "PASS: convert.cpp handles empty matrices in convertTo"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convert.cpp should handle empty matrices in convertTo" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: copy.cpp should have early empty check before isUMat check
if grep -B10 'if( _dst.isUMat() )' modules/core/src/copy.cpp | grep -q 'if( empty() )'; then
    echo "PASS: copy.cpp has early empty check before isUMat"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: copy.cpp should have early empty check before isUMat" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: agast.cpp should handle empty images
if grep -q 'if(_image.empty())' modules/features2d/src/agast.cpp; then
    echo "PASS: agast.cpp handles empty images"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: agast.cpp should handle empty images" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: fast.cpp should handle empty images
if grep -q 'if(_image.empty())' modules/features2d/src/fast.cpp; then
    echo "PASS: fast.cpp handles empty images"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: fast.cpp should handle empty images" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: gftt.cpp should handle empty images
if grep -q 'if(_image.empty())' modules/features2d/src/gftt.cpp; then
    echo "PASS: gftt.cpp handles empty images"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gftt.cpp should handle empty images" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: hough.cpp should use release() instead of assign for empty results
if grep -A2 'if (total_points <= 0)' modules/imgproc/src/hough.cpp | grep -q '_lines.release()'; then
    echo "PASS: hough.cpp uses release() for empty HoughLines results"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: hough.cpp should use release() for empty HoughLines results" >&2
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
