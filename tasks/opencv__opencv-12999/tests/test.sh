#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_chesscorners.cpp" "modules/calib3d/test/test_chesscorners.cpp"

checks_passed=0
checks_failed=0

# PR #12999: Fix circles grid clustering logic
# For harbor testing:
# - HEAD (ce00d38bd918e229ce5967a824e493a57d883111): Fixed version with proper circle counting
# - BASE (after bug.patch): Buggy version with simplified distance-only logic
# - FIXED (after fix.patch): Back to fixed version

# Check 1: circlesgrid.cpp should have pointLineDistance function in fixed version
if grep -q 'double pointLineDistance(const cv::Point2f &p, const cv::Vec4f &line)' modules/calib3d/src/circlesgrid.cpp; then
    echo "PASS: circlesgrid.cpp has pointLineDistance function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: circlesgrid.cpp missing pointLineDistance function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: getSortedCorners should have patternPoints parameter in fixed version
if grep -q 'void CirclesGridClusterFinder::getSortedCorners(const std::vector<cv::Point2f> &hull2f, const std::vector<cv::Point2f> &patternPoints,' modules/calib3d/src/circlesgrid.cpp; then
    echo "PASS: getSortedCorners has patternPoints parameter - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: getSortedCorners missing patternPoints parameter - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: circlesgrid.hpp should declare getSortedCorners with patternPoints parameter
if grep -q 'getSortedCorners(const std::vector<cv::Point2f> &hull2f, const std::vector<cv::Point2f> &patternPoints,' modules/calib3d/src/circlesgrid.hpp; then
    echo "PASS: circlesgrid.hpp declares getSortedCorners with patternPoints - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: circlesgrid.hpp missing patternPoints in getSortedCorners declaration - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: circlesgrid.cpp should use circleCount01/circleCount12 logic in fixed version
if grep -q 'size_t circleCount01 = 0;' modules/calib3d/src/circlesgrid.cpp && \
   grep -q 'size_t circleCount12 = 0;' modules/calib3d/src/circlesgrid.cpp; then
    echo "PASS: circlesgrid.cpp uses circleCount01/circleCount12 logic - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: circlesgrid.cpp missing circle counting logic - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: circlesgrid.cpp should call getSortedCorners with patternPoints in findGrid
if grep -q 'getSortedCorners(hull2f, patternPoints, corners, outsideCorners, sortedCorners);' modules/calib3d/src/circlesgrid.cpp; then
    echo "PASS: findGrid calls getSortedCorners with patternPoints - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: findGrid missing patternPoints in getSortedCorners call - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_chesscorners.cpp should have TEST(Calib3d_CirclesPatternDetectorWithClustering, accuracy) in fixed version
if grep -q 'TEST(Calib3d_CirclesPatternDetectorWithClustering, accuracy)' modules/calib3d/test/test_chesscorners.cpp; then
    echo "PASS: test_chesscorners.cpp has CirclesPatternDetectorWithClustering test - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_chesscorners.cpp missing CirclesPatternDetectorWithClustering test - buggy version" >&2
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
