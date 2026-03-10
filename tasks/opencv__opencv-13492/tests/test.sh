#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_operations.cpp" "modules/core/test/test_operations.cpp"

checks_passed=0
checks_failed=0

# PR #13492: The PR adds template operator overloads for Mat/Matx operations
# and a corresponding test. For harbor testing:
# - HEAD (cd169941f2f9c0d38f7dce5992ae3b616d91706d): Has the operators and test (current git state)
# - BASE (after bug.patch): Operators and test removed (simulates the buggy state)
# - FIXED (after fix.patch): Operators and test restored (back to HEAD/current git state)

# Check 1: TestMatMatxCastSum function should exist in test_operations.cpp
if grep -q 'bool CV_OperationsTest::TestMatMatxCastSum()' modules/core/test/test_operations.cpp; then
    echo "PASS: test_operations.cpp has TestMatMatxCastSum function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_operations.cpp missing TestMatMatxCastSum function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: TestMatMatxCastSum should be declared in the class
if grep -q 'bool TestMatMatxCastSum();' modules/core/test/test_operations.cpp; then
    echo "PASS: test_operations.cpp has TestMatMatxCastSum declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_operations.cpp missing TestMatMatxCastSum declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: TestMatMatxCastSum should be called in run method
if grep -q 'if (!TestMatMatxCastSum())' modules/core/test/test_operations.cpp; then
    echo "PASS: test_operations.cpp calls TestMatMatxCastSum in run() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_operations.cpp doesn't call TestMatMatxCastSum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: mat.hpp should have operator + overloads for Mat/Matx
if grep -q 'MatExpr operator + (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator + (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator + overloads for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator + overloads for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: mat.hpp should have operator - overloads for Mat/Matx
if grep -q 'MatExpr operator - (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator - (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator - overloads for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator - overloads for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: mat.hpp should have operator * overloads for Mat/Matx
if grep -q 'MatExpr operator \* (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator \* (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator * overloads for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator * overloads for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: mat.hpp should have operator / overloads for Mat/Matx
if grep -q 'MatExpr operator / (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator / (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator / overloads for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator / overloads for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: mat.hpp should have comparison operator overloads
if grep -q 'MatExpr operator < (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator <= (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator == (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has comparison operator overloads for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing comparison operator overloads for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: mat.hpp should have bitwise operator overloads
if grep -q 'MatExpr operator & (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator | (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator \^ (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has bitwise operator overloads for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing bitwise operator overloads for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: mat.hpp should have min/max function overloads
if grep -q 'MatExpr min (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr max (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has min/max function overloads for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing min/max function overloads for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: operations.hpp should have CV_MAT_AUG_OPERATOR_TN macro definition
if grep -q '#define CV_MAT_AUG_OPERATOR_TN(op, cvop, A)' modules/core/include/opencv2/core/operations.hpp; then
    echo "PASS: operations.hpp has CV_MAT_AUG_OPERATOR_TN macro (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: operations.hpp missing CV_MAT_AUG_OPERATOR_TN macro (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: operations.hpp should use CV_MAT_AUG_OPERATOR_TN for += operator
if grep -q 'CV_MAT_AUG_OPERATOR_TN(+=, cv::add(a,Mat(b),a), Mat)' modules/core/include/opencv2/core/operations.hpp; then
    echo "PASS: operations.hpp uses CV_MAT_AUG_OPERATOR_TN for += (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: operations.hpp missing CV_MAT_AUG_OPERATOR_TN usage for += (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: operations.hpp should undef CV_MAT_AUG_OPERATOR_TN at the end
if grep -q '#undef CV_MAT_AUG_OPERATOR_TN' modules/core/include/opencv2/core/operations.hpp; then
    echo "PASS: operations.hpp has #undef CV_MAT_AUG_OPERATOR_TN (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: operations.hpp missing #undef CV_MAT_AUG_OPERATOR_TN (buggy version)" >&2
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
