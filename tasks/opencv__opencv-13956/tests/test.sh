#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/misc/java/test"
cp "/tests/modules/core/misc/java/test/MatTest.java" "modules/core/misc/java/test/MatTest.java"
mkdir -p "modules/java/test/android_test/src/org/opencv/test"
cp "/tests/modules/java/test/android_test/src/org/opencv/test/OpenCVTestCase.java" "modules/java/test/android_test/src/org/opencv/test/OpenCVTestCase.java"
mkdir -p "modules/java/test/pure_test/src/org/opencv/test"
cp "/tests/modules/java/test/pure_test/src/org/opencv/test/OpenCVTestCase.java" "modules/java/test/pure_test/src/org/opencv/test/OpenCVTestCase.java"

checks_passed=0
checks_failed=0

# The fix adds several Java API methods to Mat class
# HEAD (6dc247141f): Has complete Mat API with all constructors and methods
# BASE (after bug.patch): Removes several Mat constructors and methods
# FIXED (after fix.patch): Restores all removed methods

# Check 1: Mat constructor with int[] sizes parameter should exist
if grep -q 'public Mat(int\[\] sizes, int type)' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: Mat(int[] sizes, int type) constructor exists (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Mat(int[] sizes, int type) constructor missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Mat constructor with int[] sizes and Scalar parameter should exist
if grep -q 'public Mat(int\[\] sizes, int type, Scalar s)' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: Mat(int[] sizes, int type, Scalar s) constructor exists (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Mat(int[] sizes, int type, Scalar s) constructor missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Mat constructor with Mat m and Range[] ranges parameter should exist
if grep -q 'public Mat(Mat m, Range\[\] ranges)' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: Mat(Mat m, Range[] ranges) constructor exists (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Mat(Mat m, Range[] ranges) constructor missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: create method with int[] sizes parameter should exist
if grep -q 'public void create(int\[\] sizes, int type)' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: create(int[] sizes, int type) method exists (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: create(int[] sizes, int type) method missing (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: copySize method should exist
if grep -q 'public void copySize(Mat m)' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: copySize(Mat m) method exists (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: copySize(Mat m) method missing (BASE version)" >&2
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
