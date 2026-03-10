#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# Check 1: Test file should exist (fixed version has it, buggy version deleted it)
if [ -f "/tests/modules/ml/misc/python/test/test_knearest.py" ]; then
    echo "PASS: test_knearest.py exists in /tests (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_knearest.py missing from /tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: KNearest::load declaration should exist in header file (fixed version)
if grep -q "static Ptr<KNearest> load(const String& filepath)" modules/ml/include/opencv2/ml.hpp; then
    echo "PASS: KNearest::load declaration found in ml.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: KNearest::load declaration missing from ml.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: KNearest::load implementation should exist in source file (fixed version)
if grep -q "Ptr<KNearest> KNearest::load(const String& filepath)" modules/ml/src/knearest.cpp; then
    echo "PASS: KNearest::load implementation found in knearest.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: KNearest::load implementation missing from knearest.cpp (buggy version)" >&2
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
