#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/features2d/misc/java/test"
cp "/tests/modules/features2d/misc/java/test/BruteForceHammingDescriptorMatcherTest.java" "modules/features2d/misc/java/test/BruteForceHammingDescriptorMatcherTest.java"
mkdir -p "modules/features2d/misc/java/test"
cp "/tests/modules/features2d/misc/java/test/BruteForceHammingLUTDescriptorMatcherTest.java" "modules/features2d/misc/java/test/BruteForceHammingLUTDescriptorMatcherTest.java"
mkdir -p "modules/features2d/misc/java/test"
cp "/tests/modules/features2d/misc/java/test/FASTFeatureDetectorTest.java" "modules/features2d/misc/java/test/FASTFeatureDetectorTest.java"
mkdir -p "modules/features2d/misc/java/test"
cp "/tests/modules/features2d/misc/java/test/ORBDescriptorExtractorTest.java" "modules/features2d/misc/java/test/ORBDescriptorExtractorTest.java"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11516: Remove deprecated Java wrapper APIs (FeatureDetector/DescriptorExtractor)

# Check 1: features2d_manual.hpp should be deleted (file should not exist)
if [ ! -f modules/features2d/misc/java/src/cpp/features2d_manual.hpp ]; then
    echo "PASS: features2d_manual.hpp has been removed"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: features2d_manual.hpp should be deleted" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: filelist should not reference features2d_manual.hpp
if ! grep -q 'misc/java/src/cpp/features2d_manual.hpp' modules/features2d/misc/java/filelist; then
    echo "PASS: filelist does not reference features2d_manual.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: filelist should not reference features2d_manual.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: filelist should still reference features2d.hpp
if grep -q 'include/opencv2/features2d.hpp' modules/features2d/misc/java/filelist; then
    echo "PASS: filelist still references features2d.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: filelist should reference features2d.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: gen_dict.json should not have const_private_list with deprecated constants
if ! grep -q '"const_private_list"' modules/features2d/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json does not have const_private_list"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json should not have const_private_list" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gen_dict.json should not reference OPPONENTEXTRACTOR
if ! grep -q 'OPPONENTEXTRACTOR' modules/features2d/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json does not reference OPPONENTEXTRACTOR"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json should not reference OPPONENTEXTRACTOR" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: gen_dict.json should not reference GRIDDETECTOR
if ! grep -q 'GRIDDETECTOR' modules/features2d/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json does not reference GRIDDETECTOR"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json should not reference GRIDDETECTOR" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: gen_dict.json should not reference PYRAMIDDETECTOR
if ! grep -q 'PYRAMIDDETECTOR' modules/features2d/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json does not reference PYRAMIDDETECTOR"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json should not reference PYRAMIDDETECTOR" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gen_dict.json should not reference DYNAMICDETECTOR
if ! grep -q 'DYNAMICDETECTOR' modules/features2d/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json does not reference DYNAMICDETECTOR"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json should not reference DYNAMICDETECTOR" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: gen_dict.json should still have class_ignore_list
if grep -q '"class_ignore_list"' modules/features2d/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json still has class_ignore_list"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json should still have class_ignore_list" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: gen_dict.json should still have type_dict
if grep -q '"type_dict"' modules/features2d/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json still has type_dict"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json should still have type_dict" >&2
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
