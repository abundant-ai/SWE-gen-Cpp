#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_drawing.cpp" "modules/imgproc/test/test_drawing.cpp"

checks_passed=0
checks_failed=0

# PR #13869 adds LineVirtualIterator functionality to OpenCV
# HEAD (68f101df8de7bff66cb4380134a49262ce641e8b): Fixed version with LineVirtualIterator support
# BASE (after bug.patch): Buggy version without LineVirtualIterator constructors
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: LineIterator should have Point-only constructor (fixed version)
if grep -q 'LineIterator( Point pt1, Point pt2,' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: LineIterator Point constructor exists in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: LineIterator Point constructor missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: LineIterator should have Size constructor (fixed version)
if grep -q 'LineIterator( Size boundingAreaSize, Point pt1, Point pt2,' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: LineIterator Size constructor exists in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: LineIterator Size constructor missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: LineIterator should have Rect constructor (fixed version)
if grep -q 'LineIterator( Rect boundingAreaRect, Point pt1, Point pt2,' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: LineIterator Rect constructor exists in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: LineIterator Rect constructor missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: LineIterator should have init method (fixed version)
if grep -q 'void init(const Mat\* img, Rect boundingAreaRect, Point pt1, Point pt2, int connectivity, bool leftToRight);' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: LineIterator init method exists in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: LineIterator init method missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: LineIterator should have ptmode member variable (fixed version)
if grep -q 'bool ptmode;' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: LineIterator ptmode member exists in imgproc.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: LineIterator ptmode member missing from imgproc.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test file should have checkLineVirtualIterator method (fixed version)
if grep -q 'virtual int checkLineVirtualIterator()' modules/imgproc/test/test_drawing.cpp; then
    echo "PASS: checkLineVirtualIterator method exists in test_drawing.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: checkLineVirtualIterator method missing from test_drawing.cpp (buggy version)" >&2
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
