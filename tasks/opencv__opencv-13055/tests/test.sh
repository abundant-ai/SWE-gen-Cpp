#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/objdetect/test"
cp "/tests/modules/objdetect/test/test_cascadeandhog.cpp" "modules/objdetect/test/test_cascadeandhog.cpp"
mkdir -p "modules/objdetect/test"
cp "/tests/modules/objdetect/test/test_precomp.hpp" "modules/objdetect/test/test_precomp.hpp"

checks_passed=0
checks_failed=0

# PR #13055: Remove legacy Haar C API
# For harbor testing:
# - HEAD (b8175f89769f8929ab302cd6a05f1e678ceab410): Fixed version with C API removed
# - BASE (after bug.patch): Buggy version with legacy C API present
# - FIXED (after fix.patch): Back to fixed version

# Check 1: objdetect_c.h should NOT exist in fixed version (removed in PR)
if [ ! -f "modules/objdetect/include/opencv2/objdetect/objdetect_c.h" ]; then
    echo "PASS: objdetect_c.h does not exist - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect_c.h exists - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: cascadedetect.cpp should NOT include objdetect_c.h (removed in fixed version)
if ! grep -q '#include "opencv2/objdetect/objdetect_c.h"' modules/objdetect/src/cascadedetect.cpp; then
    echo "PASS: cascadedetect.cpp does not include objdetect_c.h - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cascadedetect.cpp includes objdetect_c.h - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: cascadedetect.cpp should NOT have CvAvgComp getRect/getNeighbors structs (removed in fixed version)
if ! grep -q 'struct getRect { Rect operator ()(const CvAvgComp& e)' modules/objdetect/src/cascadedetect.cpp; then
    echo "PASS: cascadedetect.cpp does not have getRect struct - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cascadedetect.cpp has getRect struct - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: cascadedetect.cpp should NOT have detectMultiScaleOldFormat function (removed in fixed version)
if ! grep -q 'detectMultiScaleOldFormat' modules/objdetect/src/cascadedetect.cpp; then
    echo "PASS: cascadedetect.cpp does not have detectMultiScaleOldFormat - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cascadedetect.cpp has detectMultiScaleOldFormat - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: haar.avx.cpp should NOT exist (removed in fixed version)
if [ ! -f "modules/objdetect/src/haar.avx.cpp" ]; then
    echo "PASS: haar.avx.cpp does not exist - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: haar.avx.cpp exists - buggy version" >&2
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
