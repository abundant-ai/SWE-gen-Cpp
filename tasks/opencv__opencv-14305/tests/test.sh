#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# Check 1: Test file test_calib3d.js should exist in /tests (fixed version)
if [ -f "/tests/modules/js/test/test_calib3d.js" ]; then
    echo "PASS: test_calib3d.js exists in /tests (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_calib3d.js missing from /tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tests.html should reference test_calib3d.js in /tests (fixed version)
if [ -f "/tests/modules/js/test/tests.html" ] && grep -q "test_calib3d.js" /tests/modules/js/test/tests.html; then
    echo "PASS: tests.html references test_calib3d.js in /tests (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tests.html does not reference test_calib3d.js in /tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tests.js should include test_calib3d.js in test array in /tests (fixed version)
if [ -f "/tests/modules/js/test/tests.js" ] && grep -q "test_calib3d.js" /tests/modules/js/test/tests.js; then
    echo "PASS: tests.js includes test_calib3d.js in /tests (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tests.js does not include test_calib3d.js in /tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: CMakeLists.txt should have 'js' in WRAP directive (fixed version)
if grep -q "WRAP java python js" modules/calib3d/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt has js in WRAP directive (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt missing js in WRAP directive (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: embindgen.py should define calib3d whitelist (fixed version)
if grep -q "calib3d = {" modules/js/src/embindgen.py; then
    echo "PASS: embindgen.py defines calib3d dictionary (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: embindgen.py missing calib3d dictionary (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: embindgen.py should include calib3d in white_list (fixed version)
if grep -q "white_list = makeWhiteList.*calib3d" modules/js/src/embindgen.py; then
    echo "PASS: embindgen.py includes calib3d in white_list (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: embindgen.py does not include calib3d in white_list (buggy version)" >&2
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
