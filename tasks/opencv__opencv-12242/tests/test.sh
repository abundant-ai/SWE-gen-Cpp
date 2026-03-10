#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/ml/test"
cp "/tests/modules/ml/test/test_mltests2.cpp" "modules/ml/test/test_mltests2.cpp"

checks_passed=0
checks_failed=0

# PR #12242: Add support for ROW_SAMPLE and COL_SAMPLE layouts in TrainData
# The fix adds getSubMatrix() function and test cases for both layouts
# For harbor testing:
# - HEAD (6e84abc746757c6de75e7c5a303b7c68f721575f): Fixed version with getSubMatrix and layout tests
# - BASE (after bug.patch): Buggy version without getSubMatrix
# - FIXED (after oracle applies fix): Back to fixed version

# Check 1: ml.hpp should declare getSubMatrix function (fixed version)
if grep -q 'static CV_WRAP Mat getSubMatrix(const Mat& matrix, const Mat& idx, int layout);' modules/ml/include/opencv2/ml.hpp; then
    echo "PASS: ml.hpp declares getSubMatrix function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ml.hpp should declare getSubMatrix function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: ml.hpp should have proper documentation for getSubMatrix (fixed version)
if grep -q 'Extract from matrix rows/cols specified by passed indexes' modules/ml/include/opencv2/ml.hpp; then
    echo "PASS: ml.hpp has getSubMatrix documentation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ml.hpp should have getSubMatrix documentation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: data.cpp should include logger.hpp (fixed version)
if grep -q '#include <opencv2/core/utils/logger.hpp>' modules/ml/src/data.cpp; then
    echo "PASS: data.cpp includes logger.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: data.cpp should include logger.hpp - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: data.cpp should have getSubMatrixImpl template function (fixed version)
if grep -q 'template<typename T>' modules/ml/src/data.cpp && grep -q 'Mat getSubMatrixImpl(const Mat& m, const Mat& idx, int layout)' modules/ml/src/data.cpp; then
    echo "PASS: data.cpp has getSubMatrixImpl template function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: data.cpp should have getSubMatrixImpl template function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: data.cpp should have getSubMatrix implementation (fixed version)
if grep -q 'Mat TrainData::getSubMatrix(const Mat& m, const Mat& idx, int layout)' modules/ml/src/data.cpp; then
    echo "PASS: data.cpp has getSubMatrix implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: data.cpp should have getSubMatrix implementation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: data.cpp should call getSubMatrix in getTestSamples (fixed version)
if grep -q 'return idx.empty() ? Mat() : getSubMatrix(samples, idx, getLayout());' modules/ml/src/data.cpp; then
    echo "PASS: data.cpp calls getSubMatrix in getTestSamples - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: data.cpp should call getSubMatrix in getTestSamples - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: data.cpp getSubVector should have deprecation warning (fixed version)
if grep -q "CV_LOG_WARNING(NULL, \"'getSubVector(const Mat& vec, const Mat& idx)' call with non-1D input is deprecated" modules/ml/src/data.cpp; then
    echo "PASS: data.cpp getSubVector has deprecation warning - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: data.cpp getSubVector should have deprecation warning - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_mltests2.cpp should have ROW_SAMPLE layout test (fixed version)
if grep -q 'TEST(TrainDataGet, layout_ROW_SAMPLE)' modules/ml/test/test_mltests2.cpp; then
    echo "PASS: test_mltests2.cpp has ROW_SAMPLE layout test - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_mltests2.cpp should have ROW_SAMPLE layout test - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_mltests2.cpp should have COL_SAMPLE layout test (fixed version)
if grep -q 'TEST(TrainDataGet, layout_COL_SAMPLE)' modules/ml/test/test_mltests2.cpp; then
    echo "PASS: test_mltests2.cpp has COL_SAMPLE layout test - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_mltests2.cpp should have COL_SAMPLE layout test - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: test_mltests2.cpp ROW_SAMPLE test should verify sample dimensions (fixed version)
if grep -q 'EXPECT_EQ(15, tsamples.rows);' modules/ml/test/test_mltests2.cpp; then
    echo "PASS: test_mltests2.cpp ROW_SAMPLE test verifies sample dimensions - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_mltests2.cpp ROW_SAMPLE test should verify sample dimensions - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: test_mltests2.cpp COL_SAMPLE test should verify transposed dimensions (fixed version)
if grep -q 'EXPECT_EQ(15, tsamples.cols);' modules/ml/test/test_mltests2.cpp; then
    echo "PASS: test_mltests2.cpp COL_SAMPLE test verifies transposed dimensions - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_mltests2.cpp COL_SAMPLE test should verify transposed dimensions - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: data.cpp should use getSubMatrix with ROW_SAMPLE layout for responses (fixed version)
if grep -q 'return getSubMatrix(responses, getTrainSampleIdx(), cv::ml::ROW_SAMPLE);' modules/ml/src/data.cpp; then
    echo "PASS: data.cpp uses getSubMatrix with ROW_SAMPLE for getTrainResponses - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: data.cpp should use getSubMatrix with ROW_SAMPLE for getTrainResponses - buggy version" >&2
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
