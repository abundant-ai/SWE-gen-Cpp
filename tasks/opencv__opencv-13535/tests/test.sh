#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_operations.cpp" "modules/core/test/test_operations.cpp"
mkdir -p "modules/features2d/test"
cp "/tests/modules/features2d/test/test_drawing.cpp" "modules/features2d/test/test_drawing.cpp"
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_filter.cpp" "modules/imgproc/test/test_filter.cpp"

checks_passed=0
checks_failed=0

# PR #13535 adds template operator overloads for Mat/Matx operations
# HEAD (85ade61ef7d95fcca19cc6d3eba532225d7790a2): Fixed version with template operators
# BASE (after bug.patch): Buggy version without template operators
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: mat.hpp should have operator+ for Mat and Matx
if grep -q 'template<typename _Tp, int m, int n> static inline' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator + (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator + (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator+ for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator+ for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: mat.hpp should have operator- for Mat and Matx
if grep -q 'MatExpr operator - (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator - (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator- for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator- for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: mat.hpp should have operator* for Mat and Matx (note: fixed version uses * not +)
if grep -q 'MatExpr operator \* (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator \* (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator* for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator* for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: mat.hpp should have operator/ for Mat and Matx
if grep -q 'MatExpr operator / (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator / (const Matx<_Tp, m, n>& a, const Mat& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has operator/ for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing operator/ for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: mat.hpp should have comparison operators (==, !=, <, >, <=, >=) for Mat and Matx
if grep -q 'MatExpr operator == (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator != (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator < (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has comparison operators for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing comparison operators for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: mat.hpp should have bitwise operators (&, |, ^) for Mat and Matx
if grep -q 'MatExpr operator & (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'MatExpr operator | (const Mat& a, const Matx<_Tp, m, n>& b)' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has bitwise operators for Mat/Matx (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing bitwise operators for Mat/Matx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: operations.hpp should have CV_MAT_AUG_OPERATOR_TN macro and its usage
if grep -q '#define CV_MAT_AUG_OPERATOR_TN' modules/core/include/opencv2/core/operations.hpp && \
   grep -q 'CV_MAT_AUG_OPERATOR_TN(+=, cv::add(a,Mat(b),a), Mat)' modules/core/include/opencv2/core/operations.hpp; then
    echo "PASS: operations.hpp has CV_MAT_AUG_OPERATOR_TN macro (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: operations.hpp missing CV_MAT_AUG_OPERATOR_TN macro (buggy version)" >&2
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
