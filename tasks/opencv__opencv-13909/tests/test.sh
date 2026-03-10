#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_logtagconfigparser.cpp" "modules/core/test/test_logtagconfigparser.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_logtagmanager.cpp" "modules/core/test/test_logtagmanager.cpp"

checks_passed=0
checks_failed=0

# PR #13909 adds log tag infrastructure to fix logging initialization/destruction issues
# HEAD (f03db4deb9639edfb4ffb5273cba6e2e063dc328): New log tag infrastructure
# BASE (after bug.patch): Old version without log tag infrastructure
# FIXED (after fix.patch): New log tag infrastructure (matches HEAD)

# Check 1: logtag.hpp header should exist (fixed version)
if [ -f "modules/core/include/opencv2/core/utils/logtag.hpp" ]; then
    echo "PASS: logtag.hpp header exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtag.hpp header missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: logtagconfigparser.hpp should exist (fixed version)
if [ -f "modules/core/src/utils/logtagconfigparser.hpp" ]; then
    echo "PASS: logtagconfigparser.hpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagconfigparser.hpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: logtagconfigparser.cpp should exist (fixed version)
if [ -f "modules/core/src/utils/logtagconfigparser.cpp" ]; then
    echo "PASS: logtagconfigparser.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagconfigparser.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: logtagmanager.hpp should exist (fixed version)
if [ -f "modules/core/src/utils/logtagmanager.hpp" ]; then
    echo "PASS: logtagmanager.hpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagmanager.hpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: logtagmanager.cpp should exist (fixed version)
if [ -f "modules/core/src/utils/logtagmanager.cpp" ]; then
    echo "PASS: logtagmanager.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagmanager.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: logtagconfig.hpp should exist (fixed version)
if [ -f "modules/core/src/utils/logtagconfig.hpp" ]; then
    echo "PASS: logtagconfig.hpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagconfig.hpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: logger.hpp should include logtag.hpp (fixed version)
if grep -q '#include "logtag.hpp"' modules/core/include/opencv2/core/utils/logger.hpp; then
    echo "PASS: logger.hpp includes logtag.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logger.hpp missing logtag.hpp include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: logger.hpp should have registerLogTag function (fixed version)
if grep -q 'registerLogTag' modules/core/include/opencv2/core/utils/logger.hpp; then
    echo "PASS: logger.hpp has registerLogTag function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logger.hpp missing registerLogTag function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: logger.hpp should have setLogTagLevel function (fixed version)
if grep -q 'setLogTagLevel' modules/core/include/opencv2/core/utils/logger.hpp; then
    echo "PASS: logger.hpp has setLogTagLevel function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logger.hpp missing setLogTagLevel function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: logger.hpp should have LogTagAuto struct (fixed version)
if grep -q 'struct LogTagAuto' modules/core/include/opencv2/core/utils/logger.hpp; then
    echo "PASS: logger.hpp has LogTagAuto struct (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logger.hpp missing LogTagAuto struct (buggy version)" >&2
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
