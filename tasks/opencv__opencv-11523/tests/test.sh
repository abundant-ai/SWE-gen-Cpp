#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_io.cpp" "modules/core/test/test_io.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_mat.cpp" "modules/core/test/test_mat.cpp"
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_thresh.cpp" "modules/imgproc/test/test_thresh.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11523: Add BIGDATA_TEST macro and --test_bigdata flag for large memory tests

# Check 1: ts_ext.hpp should declare runBigDataTests extern variable
if grep -q 'extern bool runBigDataTests;' modules/ts/include/opencv2/ts/ts_ext.hpp; then
    echo "PASS: ts_ext.hpp declares runBigDataTests"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_ext.hpp should declare 'extern bool runBigDataTests;'" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: ts_ext.hpp should define TEST_ macro with BODY_IMPL parameter
if grep -q '#define TEST_(test_case_name, test_name, BODY_IMPL)' modules/ts/include/opencv2/ts/ts_ext.hpp; then
    echo "PASS: ts_ext.hpp defines TEST_ macro with BODY_IMPL parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_ext.hpp should define TEST_ macro with BODY_IMPL parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: ts_ext.hpp should use BODY_IMPL in TEST_ macro definition
if grep -q 'void GTEST_TEST_CLASS_NAME_(test_case_name, test_name)::TestBody() BODY_IMPL' modules/ts/include/opencv2/ts/ts_ext.hpp; then
    echo "PASS: ts_ext.hpp uses BODY_IMPL in TEST_ macro"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_ext.hpp should use BODY_IMPL in TEST_ macro definition" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: ts_ext.hpp should redefine TEST macro using TEST_
if grep -q '#define TEST(test_case_name, test_name) TEST_(test_case_name, test_name, CV__TEST_BODY_IMPL)' modules/ts/include/opencv2/ts/ts_ext.hpp; then
    echo "PASS: ts_ext.hpp redefines TEST macro using TEST_"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_ext.hpp should redefine TEST macro using TEST_" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: ts_ext.hpp should define CV__TEST_BIGDATA_BODY_IMPL macro
if grep -q '#define CV__TEST_BIGDATA_BODY_IMPL(name)' modules/ts/include/opencv2/ts/ts_ext.hpp && \
   grep -q 'if (!cvtest::runBigDataTests)' modules/ts/include/opencv2/ts/ts_ext.hpp && \
   grep -q 'printf("\[     SKIP \] BigData tests are disabled\\n");' modules/ts/include/opencv2/ts/ts_ext.hpp; then
    echo "PASS: ts_ext.hpp defines CV__TEST_BIGDATA_BODY_IMPL macro with skip logic"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_ext.hpp should define CV__TEST_BIGDATA_BODY_IMPL macro" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: ts_ext.hpp should define BIGDATA_TEST macro for x64/aarch64
if grep -q '#if defined(_M_X64) || defined(__x86_64__) || defined(__aarch64__)' modules/ts/include/opencv2/ts/ts_ext.hpp && \
   grep -q '#define BIGDATA_TEST(test_case_name, test_name) TEST_(BigData_ ## test_case_name, test_name, CV__TEST_BIGDATA_BODY_IMPL)' modules/ts/include/opencv2/ts/ts_ext.hpp; then
    echo "PASS: ts_ext.hpp defines BIGDATA_TEST macro for 64-bit platforms"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_ext.hpp should define BIGDATA_TEST macro for 64-bit platforms" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: ts_ext.hpp should define BIGDATA_TEST with DISABLED_ for other platforms
if grep -q '#define BIGDATA_TEST(test_case_name, test_name) TEST_(BigData_ ## test_case_name, DISABLED_ ## test_name, CV__TEST_BIGDATA_BODY_IMPL)' modules/ts/include/opencv2/ts/ts_ext.hpp; then
    echo "PASS: ts_ext.hpp defines BIGDATA_TEST with DISABLED_ for non-64-bit platforms"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_ext.hpp should define BIGDATA_TEST with DISABLED_ for non-64-bit platforms" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: ts.cpp should define runBigDataTests variable
if grep -q 'bool runBigDataTests = false;' modules/ts/src/ts.cpp; then
    echo "PASS: ts.cpp defines runBigDataTests variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.cpp should define 'bool runBigDataTests = false;'" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: ts.cpp should add test_bigdata command line option
if grep -q '{ test_bigdata       |false    |run BigData tests (>=2Gb) }' modules/ts/src/ts.cpp; then
    echo "PASS: ts.cpp adds test_bigdata command line option"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.cpp should add test_bigdata command line option" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: ts.cpp should parse test_bigdata option
if grep -q 'runBigDataTests = parser.get<bool>("test_bigdata");' modules/ts/src/ts.cpp; then
    echo "PASS: ts.cpp parses test_bigdata option"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.cpp should parse test_bigdata option" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: test_io.cpp should use BIGDATA_TEST macro
if grep -q 'BIGDATA_TEST(Core_InputOutput, huge)' modules/core/test/test_io.cpp; then
    echo "PASS: test_io.cpp uses BIGDATA_TEST macro"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_io.cpp should use BIGDATA_TEST macro" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_mat.cpp should use BIGDATA_TEST macro
if grep -q 'BIGDATA_TEST(Mat, push_back_regression_4158)' modules/core/test/test_mat.cpp; then
    echo "PASS: test_mat.cpp uses BIGDATA_TEST macro"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_mat.cpp should use BIGDATA_TEST macro" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_thresh.cpp should use BIGDATA_TEST macro
if grep -q 'BIGDATA_TEST(Imgproc_Threshold, huge)' modules/imgproc/test/test_thresh.cpp; then
    echo "PASS: test_thresh.cpp uses BIGDATA_TEST macro"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_thresh.cpp should use BIGDATA_TEST macro" >&2
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
