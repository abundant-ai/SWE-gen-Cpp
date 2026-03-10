#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_lpsolver.cpp" "modules/core/test/test_lpsolver.cpp"

checks_passed=0
checks_failed=0

# PR #12848: Change solveLP API from (Mat&, Mat&, Mat&) to (InputArray, InputArray, OutputArray)
# For harbor testing:
# - HEAD (954536073d75c3cb15e11adfe949145bb93fdf7d): Fixed version with InputArray/OutputArray
# - BASE (after bug.patch): Buggy version with const Mat&/Mat& parameters
# - FIXED (after fix.patch): Back to fixed version with InputArray/OutputArray

# Check 1: optim.hpp should have InputArray/OutputArray signature
if grep -q 'CV_EXPORTS_W int solveLP(InputArray Func, InputArray Constr, OutputArray z);' modules/core/include/opencv2/core/optim.hpp; then
    echo "PASS: optim.hpp has InputArray/OutputArray signature - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: optim.hpp missing InputArray/OutputArray signature - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: lpsolver.cpp should have InputArray/OutputArray parameters
if grep -q 'int solveLP(InputArray Func_, InputArray Constr_, OutputArray z_)' modules/core/src/lpsolver.cpp; then
    echo "PASS: lpsolver.cpp has InputArray/OutputArray parameters - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lpsolver.cpp missing InputArray/OutputArray parameters - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: lpsolver.cpp should call getMat() on InputArray parameters
if grep -q 'Mat Func = Func_.getMat();' modules/core/src/lpsolver.cpp && \
   grep -q 'Mat Constr = Constr_.getMat();' modules/core/src/lpsolver.cpp; then
    echo "PASS: lpsolver.cpp calls getMat() on InputArray - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lpsolver.cpp missing getMat() calls - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: lpsolver.cpp should validate output type with fixedType()
if grep -q 'if (z_.fixedType())' modules/core/src/lpsolver.cpp; then
    echo "PASS: lpsolver.cpp checks fixedType() for validation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lpsolver.cpp missing fixedType() check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: lpsolver.cpp should support CV_32FC1 and CV_32SC1 output types
if grep -q 'CV_CheckType(z_.type(), z_.type() == CV_64FC1 || z_.type() == CV_32FC1 || z_.type() == CV_32SC1' modules/core/src/lpsolver.cpp; then
    echo "PASS: lpsolver.cpp validates CV_32FC1 and CV_32SC1 types - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lpsolver.cpp missing type validation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: lpsolver.cpp should use copyTo() to write to OutputArray
if grep -q 'z.copyTo(z_);' modules/core/src/lpsolver.cpp; then
    echo "PASS: lpsolver.cpp uses copyTo() for OutputArray - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lpsolver.cpp missing copyTo() call - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_lpsolver.cpp should have plain call for Mat1f (no EXPECT_* in fixed version)
if grep -q 'Mat1f z_float; cv::solveLP(A, B, z_float);' modules/core/test/test_lpsolver.cpp && \
   ! grep -q 'EXPECT_ANY_THROW(Mat1f z_float;' modules/core/test/test_lpsolver.cpp; then
    echo "PASS: test has plain Mat1f call - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test missing plain Mat1f call or has incorrect EXPECT_* - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_lpsolver.cpp should have plain call for Mat1d (no EXPECT_* in fixed version)
if grep -q 'Mat1d z_double; cv::solveLP(A, B, z_double);' modules/core/test/test_lpsolver.cpp && \
   ! grep -q 'EXPECT_NO_THROW(Mat1d z_double;' modules/core/test/test_lpsolver.cpp; then
    echo "PASS: test has plain Mat1d call - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test missing plain Mat1d call or has incorrect EXPECT_* - buggy version" >&2
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
