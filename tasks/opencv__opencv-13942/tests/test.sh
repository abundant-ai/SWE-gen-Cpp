#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_lsd.cpp" "modules/imgproc/test/test_lsd.cpp"

checks_passed=0
checks_failed=0

# PR #13942 removes the LSD (Line Segment Detector) implementation due to license conflict
# HEAD (3ba49ccecc773592a3e8d68ad9f5b06196dae6b6): Implementation REMOVED (the actual PR state)
# BASE (after bug.patch): Problematic implementation EXISTS (simulated buggy state)
# FIXED (after fix.patch): Implementation REMOVED with proper documentation (matches HEAD)

# Check 1: Documentation notes about removed implementation SHOULD exist in header (fixed version)
if grep -q '@note Implementation has been removed due original code license conflict' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: imgproc.hpp contains removal note (fixed version - properly documented removal)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgproc.hpp missing removal note (buggy version - has problematic implementation)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: LSD implementation constants should NOT exist in lsd.cpp (fixed version)
if grep -q 'RELATIVE_ERROR_FACTOR' modules/imgproc/src/lsd.cpp; then
    echo "FAIL: lsd.cpp contains RELATIVE_ERROR_FACTOR constant (buggy version - problematic implementation exists)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: lsd.cpp missing RELATIVE_ERROR_FACTOR constant (fixed version - implementation properly removed)"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: Helper function double_equal should NOT exist in lsd.cpp (fixed version)
if grep -q 'bool double_equal' modules/imgproc/src/lsd.cpp; then
    echo "FAIL: lsd.cpp contains double_equal function (buggy version - problematic implementation exists)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: lsd.cpp missing double_equal function (fixed version - implementation properly removed)"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: Log gamma functions should NOT exist in lsd.cpp (fixed version)
if grep -q 'log_gamma_windschitl' modules/imgproc/src/lsd.cpp; then
    echo "FAIL: lsd.cpp contains log_gamma_windschitl function (buggy version - problematic implementation exists)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: lsd.cpp missing log_gamma_windschitl function (fixed version - implementation properly removed)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: Edge structure should NOT be defined in lsd.cpp (fixed version)
if grep -q 'struct edge' modules/imgproc/src/lsd.cpp; then
    echo "FAIL: lsd.cpp contains edge struct definition (buggy version - problematic implementation exists)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: lsd.cpp missing edge struct definition (fixed version - implementation properly removed)"
    checks_passed=$((checks_passed + 1))
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
