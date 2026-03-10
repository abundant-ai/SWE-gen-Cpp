#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/features2d/misc/java/test"
cp "/tests/modules/features2d/misc/java/test/Features2dTest.java" "modules/features2d/misc/java/test/Features2dTest.java"

checks_passed=0
checks_failed=0

# PR #13471: The PR adds support for enum struct/class in the parser and fixes Java generator
# For harbor testing:
# - HEAD (6fbcb283b94043cbb91dfaee3cdda9464cb055d1): Has the fixes (current git state)
# - BASE (after bug.patch): Fixes removed (simulates the buggy state)
# - FIXED (after fix.patch): Fixes restored (back to HEAD/current git state)

# Check 1: hdr_parser.py should have enum struct/class handling
if grep -q 'if block_type in \["enum struct", "enum class"\] and block_name == name:' modules/python/src2/hdr_parser.py && \
   grep -q 'continue' modules/python/src2/hdr_parser.py | head -1; then
    echo "PASS: hdr_parser.py has enum struct/class handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: hdr_parser.py missing enum struct/class handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gen_java.py should have proper if-else structure for class wrapping
if grep -q 'if not self.isWrapped(constinfo.classname):' modules/java/generator/gen_java.py && \
   grep -q "constinfo.name = constinfo.classname + '_' + constinfo.name" modules/java/generator/gen_java.py && \
   grep -q "constinfo.classname = ''" modules/java/generator/gen_java.py; then
    echo "PASS: gen_java.py has proper class wrapping logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_java.py missing proper class wrapping logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: SURFFLANNMatchingDemo.java should use DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS
if grep -q 'Features2d.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS' samples/java/tutorial_code/features2D/feature_flann_matcher/SURFFLANNMatchingDemo.java; then
    echo "PASS: SURFFLANNMatchingDemo.java uses DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SURFFLANNMatchingDemo.java uses NOT_DRAW_SINGLE_POINTS (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: SURFFLANNMatchingHomographyDemo.java should use DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS
if grep -q 'Features2d.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS' samples/java/tutorial_code/features2D/feature_homography/SURFFLANNMatchingHomographyDemo.java; then
    echo "PASS: SURFFLANNMatchingHomographyDemo.java uses DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SURFFLANNMatchingHomographyDemo.java uses NOT_DRAW_SINGLE_POINTS (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Features2dTest.java should have MatOfInt import
if grep -q 'import org.opencv.core.MatOfInt;' modules/features2d/misc/java/test/Features2dTest.java; then
    echo "PASS: Features2dTest.java has MatOfInt import (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Features2dTest.java missing MatOfInt import (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Features2dTest.java should have Scalar import
if grep -q 'import org.opencv.core.Scalar;' modules/features2d/misc/java/test/Features2dTest.java; then
    echo "PASS: Features2dTest.java has Scalar import (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Features2dTest.java missing Scalar import (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Features2dTest.java should have testDrawKeypoints method
if grep -q 'public void testDrawKeypoints()' modules/features2d/misc/java/test/Features2dTest.java; then
    echo "PASS: Features2dTest.java has testDrawKeypoints method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Features2dTest.java missing testDrawKeypoints method (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Features2dTest.java should have Features2d.drawKeypoints call
if grep -q 'Features2d.drawKeypoints' modules/features2d/misc/java/test/Features2dTest.java; then
    echo "PASS: Features2dTest.java has Features2d.drawKeypoints call (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Features2dTest.java missing Features2d.drawKeypoints call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: Features2dTest.java should have DrawMatchesFlags_DRAW_OVER_OUTIMG
if grep -q 'Features2d.DrawMatchesFlags_DRAW_OVER_OUTIMG' modules/features2d/misc/java/test/Features2dTest.java; then
    echo "PASS: Features2dTest.java has DrawMatchesFlags_DRAW_OVER_OUTIMG (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Features2dTest.java missing DrawMatchesFlags_DRAW_OVER_OUTIMG (buggy version)" >&2
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
