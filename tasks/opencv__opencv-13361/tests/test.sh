#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/features2d/test"
cp "/tests/modules/features2d/test/test_brisk.cpp" "modules/features2d/test/test_brisk.cpp"

checks_passed=0
checks_failed=0

# PR #13361: The PR adds parameter get/set methods to BRISK class
# For harbor testing:
# - HEAD (cf7c7ba63cb5f02fc4db866dac4c36dd2b731838): BRISK has get/set methods (fixed version)
# - BASE (after bug.patch): BRISK missing get/set methods (buggy version)
# - FIXED (after fix.patch): BRISK has get/set methods again (back to HEAD)

# Check 1: features2d.hpp should have setThreshold/getThreshold declarations
if grep -q 'virtual void setThreshold(int threshold)' modules/features2d/include/opencv2/features2d.hpp && \
   grep -q 'virtual int getThreshold() const' modules/features2d/include/opencv2/features2d.hpp; then
    echo "PASS: features2d.hpp has threshold get/set methods (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: features2d.hpp missing threshold get/set methods (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: features2d.hpp should have setOctaves/getOctaves declarations
if grep -q 'virtual void setOctaves(int octaves)' modules/features2d/include/opencv2/features2d.hpp && \
   grep -q 'virtual int getOctaves() const' modules/features2d/include/opencv2/features2d.hpp; then
    echo "PASS: features2d.hpp has octaves get/set methods (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: features2d.hpp missing octaves get/set methods (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: brisk.cpp should have setThreshold implementation
if grep -q 'virtual void setThreshold(int threshold_in) CV_OVERRIDE' modules/features2d/src/brisk.cpp; then
    echo "PASS: brisk.cpp has setThreshold implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: brisk.cpp missing setThreshold implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: brisk.cpp should have getThreshold implementation
if grep -q 'virtual int getThreshold() const CV_OVERRIDE' modules/features2d/src/brisk.cpp; then
    echo "PASS: brisk.cpp has getThreshold implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: brisk.cpp missing getThreshold implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: brisk.cpp should have setOctaves implementation
if grep -q 'virtual void setOctaves(int octaves_in) CV_OVERRIDE' modules/features2d/src/brisk.cpp; then
    echo "PASS: brisk.cpp has setOctaves implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: brisk.cpp missing setOctaves implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: brisk.cpp should have getOctaves implementation
if grep -q 'virtual int getOctaves() const CV_OVERRIDE' modules/features2d/src/brisk.cpp; then
    echo "PASS: brisk.cpp has getOctaves implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: brisk.cpp missing getOctaves implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_brisk.cpp should test the parameter get/set functions
if grep -q 'detectorTyped->setOctaves(3)' modules/features2d/test/test_brisk.cpp && \
   grep -q 'detectorTyped->setThreshold(30)' modules/features2d/test/test_brisk.cpp; then
    echo "PASS: test_brisk.cpp tests parameter get/set functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_brisk.cpp missing parameter get/set tests (buggy version)" >&2
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
