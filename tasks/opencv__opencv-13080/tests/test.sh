#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_mat.cpp" "modules/core/test/test_mat.cpp"

checks_passed=0
checks_failed=0

# PR #13080: Fix strided single-column matrix handling in core operations
# For harbor testing:
# - HEAD (50595239371def45aafd35540ed747caad5006e9): Fixed version with proper reshape checks
# - BASE (after bug.patch): Buggy version with removed checks
# - FIXED (after fix.patch): Back to fixed version

# Check 1: arithm.cpp binary_op should have reshape check (line ~202)
if grep -q 'if (_dst.isVector() && dst.size() != src1.size())  // https://github.com/opencv/opencv/pull/4159' modules/core/src/arithm.cpp; then
    echo "PASS: arithm.cpp binary_op has reshape check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp binary_op missing reshape check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: arithm.cpp arithm_op should have reshape check (line ~633)
if grep -A 2 'Mat src1 = psrc1->getMat(), src2 = psrc2->getMat(), dst = _dst.getMat();' modules/core/src/arithm.cpp | grep -q 'if (_dst.isVector() && dst.size() != src1.size())'; then
    echo "PASS: arithm.cpp arithm_op has reshape check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp arithm_op missing reshape check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: arithm.cpp compare should have reshape check (line ~1282)
if grep -A 3 'Mat dst = _dst.getMat();' modules/core/src/arithm.cpp | grep -q 'if (_dst.isVector() && dst.size() != src1.size())'; then
    echo "PASS: arithm.cpp compare has reshape check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp compare missing reshape check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: convert.cpp should have reshape checks (count occurrences)
convert_cpp_count=$(grep -c 'if (_dst.isVector() && dst.size() != src.size())' modules/core/src/convert.cpp 2>/dev/null || echo 0)
if [ "$convert_cpp_count" -ge 2 ]; then
    echo "PASS: convert.cpp has reshape checks ($convert_cpp_count occurrences) - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convert.cpp missing reshape checks (found $convert_cpp_count, expected >= 2) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: convert_scale.cpp should have reshape check
if grep -q 'if (_dst.isVector() && dst.size() != src.size())' modules/core/src/convert_scale.cpp; then
    echo "PASS: convert_scale.cpp has reshape check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convert_scale.cpp missing reshape check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: copy.cpp should have reshape checks (count occurrences)
copy_cpp_count=$(grep -c 'if (_dst.isVector() && dst.size() != size())' modules/core/src/copy.cpp 2>/dev/null || echo 0)
if [ "$copy_cpp_count" -ge 2 ]; then
    echo "PASS: copy.cpp has reshape checks ($copy_cpp_count occurrences) - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: copy.cpp missing reshape checks (found $copy_cpp_count, expected >= 2) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: precomp.hpp should have CV_Assert in 2-mat getContinuousSize
if grep -A 2 'inline Size getContinuousSize( const Mat& m1, const Mat& m2, int widthScale=1 )' modules/core/src/precomp.hpp | grep -q 'CV_Assert(m1.size() == m2.size());'; then
    echo "PASS: precomp.hpp has CV_Assert in 2-mat getContinuousSize - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: precomp.hpp missing CV_Assert in 2-mat getContinuousSize - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: precomp.hpp should have CV_Assert in 3-mat getContinuousSize (count total CV_Asserts)
precomp_assert_count=$(grep -c 'CV_Assert(m1.size() == m2.size());' modules/core/src/precomp.hpp 2>/dev/null || echo 0)
if [ "$precomp_assert_count" -ge 2 ]; then
    echo "PASS: precomp.hpp has CV_Asserts ($precomp_assert_count occurrences) - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: precomp.hpp missing CV_Asserts (found $precomp_assert_count, expected >= 2) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: precomp.hpp should NOT have 4-mat getContinuousSize (buggy version has it)
if grep -q 'const Mat& m4,' modules/core/src/precomp.hpp; then
    echo "FAIL: precomp.hpp has 4-mat getContinuousSize - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: precomp.hpp doesn't have 4-mat getContinuousSize - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 10: precomp.hpp should NOT have 5-mat getContinuousSize (buggy version has it)
if grep -q 'const Mat& m5,' modules/core/src/precomp.hpp; then
    echo "FAIL: precomp.hpp has 5-mat getContinuousSize - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: precomp.hpp doesn't have 5-mat getContinuousSize - fixed version"
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
