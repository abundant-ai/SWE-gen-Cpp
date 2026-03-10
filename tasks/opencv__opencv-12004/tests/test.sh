#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_arithm.cpp" "modules/core/test/test_arithm.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_concatenation.cpp" "modules/core/test/test_concatenation.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_rand.cpp" "modules/core/test/test_rand.cpp"

checks_passed=0
checks_failed=0

# PR #12004: Fix empty input validation in core matrix operations

# Check 1: arithm.cpp should have CV_Assert for matching empty state
if grep -q 'CV_Assert(_src1.empty() == _src2.empty());' modules/core/src/arithm.cpp 2>/dev/null; then
    echo "PASS: arithm.cpp has CV_Assert for matching empty state"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp should have CV_Assert(_src1.empty() == _src2.empty())" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: arithm.cpp should check both empty with AND condition
if grep -q 'if (_src1.empty() && _src2.empty())' modules/core/src/arithm.cpp 2>/dev/null; then
    echo "PASS: arithm.cpp checks both empty with && condition"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp should use && for empty check (not ||)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: arithm.cpp should NOT use OR condition for empty check
if ! grep -q 'if(_src1.empty() || _src2.empty())' modules/core/src/arithm.cpp 2>/dev/null; then
    echo "PASS: arithm.cpp does not use incorrect OR condition"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp should not use || for empty check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: copy.cpp should have proper empty check formatting
if grep -q 'if (this->empty())' modules/core/src/copy.cpp 2>/dev/null; then
    echo "PASS: copy.cpp has proper empty check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: copy.cpp should have multiline empty check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: mean.cpp should have CV_Assert for non-empty source
if grep -q 'CV_Assert(!_src.empty());' modules/core/src/mean.cpp 2>/dev/null; then
    echo "PASS: mean.cpp has CV_Assert for non-empty source"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mean.cpp should have CV_Assert(!_src.empty())" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: mean.cpp should have mask assertion before getMat in meanStdDev function
if grep -A10 'void cv::meanStdDev' modules/core/src/mean.cpp 2>/dev/null | grep -q 'CV_Assert( _mask.empty() || _mask.type() == CV_8UC1 );'; then
    echo "PASS: mean.cpp has mask assertion in correct position"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mean.cpp should have mask assertion before getMat" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: rand.cpp should have CV_Assert for non-empty mat
if grep -q 'CV_Assert(!_mat.empty());' modules/core/src/rand.cpp 2>/dev/null; then
    echo "PASS: rand.cpp has CV_Assert for non-empty mat"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: rand.cpp should have CV_Assert(!_mat.empty())" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: rand.cpp should NOT have early return for empty mat
if ! grep -A2 'void RNG::fill' modules/core/src/rand.cpp 2>/dev/null | grep -q 'if (_mat.empty())'; then
    echo "PASS: rand.cpp does not have incorrect early return"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: rand.cpp should not have early return for empty mat" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_arithm.cpp should use EXPECT_NO_THROW for empty comparison
if grep -q 'EXPECT_NO_THROW(cv::compare(temp, temp, dst1, cv::CMP_EQ));' modules/core/test/test_arithm.cpp 2>/dev/null; then
    echo "PASS: test_arithm.cpp uses EXPECT_NO_THROW for empty comparison"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp should use EXPECT_NO_THROW for empty comparison" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: test_arithm.cpp should use EXPECT_THROW for mismatched empty
if grep -q 'EXPECT_THROW(dst2 = temp > 5, cv::Exception);' modules/core/test/test_arithm.cpp 2>/dev/null; then
    echo "PASS: test_arithm.cpp uses EXPECT_THROW for mismatched empty"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp should use EXPECT_THROW for mismatched empty" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: test_arithm.cpp should NOT have bare compare call for empty
if ! grep -q 'cv::compare(temp, temp, dst1, cv::CMP_EQ);' modules/core/test/test_arithm.cpp 2>/dev/null | grep -v 'EXPECT_NO_THROW'; then
    echo "PASS: test_arithm.cpp wraps compare in EXPECT_NO_THROW"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp should wrap compare in EXPECT_NO_THROW" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_arithm.cpp should use EXPECT_THROW for size mismatch
if grep -q 'EXPECT_THROW(cv::compare(A, B, C, CMP_LT), cv::Exception);' modules/core/test/test_arithm.cpp 2>/dev/null; then
    echo "PASS: test_arithm.cpp uses EXPECT_THROW for size mismatch"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp should use EXPECT_THROW for size mismatch" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_concatenation.cpp should use simple TEST structure
if grep -q 'TEST(Core_Concatenation, empty)' modules/core/test/test_concatenation.cpp 2>/dev/null; then
    echo "PASS: test_concatenation.cpp has simple TEST structure"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_concatenation.cpp should have simple TEST structure" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: test_concatenation.cpp should NOT have Core_ConcatenationTest class
if ! grep -q 'class Core_ConcatenationTest' modules/core/test/test_concatenation.cpp 2>/dev/null; then
    echo "PASS: test_concatenation.cpp does not have test class"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_concatenation.cpp should not have Core_ConcatenationTest class" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: test_concatenation.cpp should have hconcat empty/empty test
if grep -q 'cv::hconcat(mat5x0, mat5x0, result);' modules/core/test/test_concatenation.cpp 2>/dev/null; then
    echo "PASS: test_concatenation.cpp has hconcat empty/empty test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_concatenation.cpp should test hconcat with empty matrices" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: test_concatenation.cpp should have hconcat empty/nonempty test
if grep -q 'cv::hconcat(mat5x0, mat5x10, result);' modules/core/test/test_concatenation.cpp 2>/dev/null; then
    echo "PASS: test_concatenation.cpp has hconcat empty/nonempty test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_concatenation.cpp should test hconcat empty/nonempty" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: test_concatenation.cpp should have vconcat tests
if grep -q 'cv::vconcat(mat0x5, mat0x5, result);' modules/core/test/test_concatenation.cpp 2>/dev/null; then
    echo "PASS: test_concatenation.cpp has vconcat tests"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_concatenation.cpp should test vconcat with empty matrices" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: test_concatenation.cpp should use EXPECT_MAT_N_DIFF for validation
if grep -q 'EXPECT_MAT_N_DIFF' modules/core/test/test_concatenation.cpp 2>/dev/null; then
    echo "PASS: test_concatenation.cpp uses EXPECT_MAT_N_DIFF"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_concatenation.cpp should use EXPECT_MAT_N_DIFF" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 19: test_concatenation.cpp should NOT use separate test cases for each combination
if ! grep -q 'TEST(Core_Concatenation, hconcat_empty_nonempty)' modules/core/test/test_concatenation.cpp 2>/dev/null; then
    echo "PASS: test_concatenation.cpp uses single test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_concatenation.cpp should not split into separate test cases" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 20: test_rand.cpp should exist and not have broken changes
if [ -f "modules/core/test/test_rand.cpp" ]; then
    echo "PASS: test_rand.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_rand.cpp should exist" >&2
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
