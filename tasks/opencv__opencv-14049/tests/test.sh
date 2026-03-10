#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_tiff.cpp" "modules/imgcodecs/test/test_tiff.cpp"

checks_passed=0
checks_failed=0

# The fix restores several changes across multiple files
# HEAD (bd1fd59fc): Has correct implementation
# BASE (after bug.patch): Removes several assertions and changes
# FIXED (after fix.patch): Restores all HEAD features

# Check 1: modules/imgproc/src/canny.cpp should have CV_DbgAssert(cn > 0)
if grep -A 3 'CV_TRACE_FUNCTION()' modules/imgproc/src/canny.cpp | grep -q 'CV_DbgAssert(cn > 0)'; then
    echo "PASS: canny.cpp has CV_DbgAssert(cn > 0) (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: canny.cpp doesn't have CV_DbgAssert(cn > 0) (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: modules/imgcodecs/test/test_tiff.cpp should have fwrite with [i] array indexing
if grep -q 'fwrite(tiff_sample_data\[i\], 86, 1, fp)' modules/imgcodecs/test/test_tiff.cpp; then
    echo "PASS: test_tiff.cpp has correct fwrite with [i] array indexing (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tiff.cpp doesn't have correct fwrite with [i] (BASE version)" >&2
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
