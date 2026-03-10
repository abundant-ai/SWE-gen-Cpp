#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/misc/java/test"
cp "/tests/modules/core/misc/java/test/MatTest.java" "modules/core/misc/java/test/MatTest.java"

checks_passed=0
checks_failed=0

# PR #12938: Add Java wrapper methods for Mat::reshape and Mat::size
# For harbor testing:
# - HEAD (92f754c6755ff898fdbd39bc7dab3edca0b96285): Fixed version with methods present
# - BASE (after bug.patch): Buggy version with methods removed
# - FIXED (after fix.patch): Back to fixed version

# Check 1: Java Mat class should have reshape(int cn, int[] newshape) method
if grep -q 'public Mat reshape(int cn, int\[\] newshape)' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: core+Mat.java has reshape(int cn, int[] newshape) method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core+Mat.java missing reshape(int cn, int[] newshape) method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Java Mat class should have size(int i) method
if grep -q 'public int size(int i)' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: core+Mat.java has size(int i) method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core+Mat.java missing size(int i) method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Java Mat class should declare n_reshape_1 native method
if grep -q 'private static native long n_reshape_1(long nativeObj, int cn, int newndims, int\[\] newsz);' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: core+Mat.java declares n_reshape_1 native method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core+Mat.java missing n_reshape_1 native method declaration - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Java Mat class should declare n_size_i native method
if grep -q 'private static native int n_size_i(long nativeObj, int i);' modules/core/misc/java/src/java/core+Mat.java; then
    echo "PASS: core+Mat.java declares n_size_i native method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core+Mat.java missing n_size_i native method declaration - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Mat.cpp should have Java_org_opencv_core_Mat_n_1reshape_11 JNI implementation
if grep -q 'JNIEXPORT jlong JNICALL Java_org_opencv_core_Mat_n_1reshape_11' modules/java/generator/src/cpp/Mat.cpp; then
    echo "PASS: Mat.cpp has n_reshape_1 JNI implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Mat.cpp missing n_reshape_1 JNI implementation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Mat.cpp should have Java_org_opencv_core_Mat_n_1size_1i__JI JNI implementation
if grep -q 'JNIEXPORT jint JNICALL Java_org_opencv_core_Mat_n_1size_1i__JI' modules/java/generator/src/cpp/Mat.cpp; then
    echo "PASS: Mat.cpp has n_size_i JNI implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Mat.cpp missing n_size_i JNI implementation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: MatTest.java should have testReshapeIntIntArray test method
if grep -q 'public void testReshapeIntIntArray()' modules/core/misc/java/test/MatTest.java; then
    echo "PASS: MatTest.java has testReshapeIntIntArray test - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MatTest.java missing testReshapeIntIntArray test - buggy version" >&2
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
