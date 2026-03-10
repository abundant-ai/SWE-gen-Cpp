#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_arithm.cpp" "modules/core/test/test_arithm.cpp"

checks_passed=0
checks_failed=0

# PR #13134: Various code quality fixes across multiple modules
# For harbor testing:
# - HEAD (f5b212a9d46bd6bf04b7d05d3d64a3a4dc80214e): Fixed version
# - BASE (after bug.patch): Buggy version
# - FIXED (after fix.patch): Back to fixed version

# Check 1: test_arithm.cpp should use modulo operator (x % 4) in testDivideChecks
if grep -q "if ((x % 4) == 2)" modules/core/test/test_arithm.cpp; then
    echo "PASS: test_arithm.cpp uses (x % 4) check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp missing (x % 4) check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: test_arithm.cpp should have else clause with cvIsNaN/cvIsInf checks
if grep -A 2 "if ((x % 4) == 2)" modules/core/test/test_arithm.cpp | grep -q "else"; then
    echo "PASS: test_arithm.cpp has else clause with additional checks - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp missing else clause - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_arithm.cpp should use modulo operators in testDivideChecksFP
if grep -q "if ((y % 3) == 0 && (x % 4) == 2)" modules/core/test/test_arithm.cpp; then
    echo "PASS: test_arithm.cpp uses (y % 3) and (x % 4) checks - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp missing modulo operators in testDivideChecksFP - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_arithm.cpp testDivide should have full parameter list (not template-only)
if grep -q "void testDivide(bool isUMat, double scale, bool largeSize, bool tailProcessing, bool roi)" modules/core/test/test_arithm.cpp; then
    echo "PASS: test_arithm.cpp testDivide has full parameter list - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp testDivide has simplified signature - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: OpenCVCompilerOptimizations.cmake should dereference legacy_flag correctly
if grep -q 'if("\${${legacy_flag}}")' cmake/OpenCVCompilerOptimizations.cmake; then
    echo "PASS: OpenCVCompilerOptimizations.cmake dereferences \${legacy_flag} correctly - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCVCompilerOptimizations.cmake has incorrect variable reference - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: qrcode.cpp should use (j != 2) condition in searchHorizontalLines
if grep -q "if (j != 2)" modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp uses (j != 2) condition - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp has incorrect condition - buggy version" >&2
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
