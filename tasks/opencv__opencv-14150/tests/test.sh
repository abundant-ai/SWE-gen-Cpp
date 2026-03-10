#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state with fixed versions)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_gcomputation_tests.cpp" "modules/gapi/test/gapi_gcomputation_tests.cpp"

checks_passed=0
checks_failed=0

# The fix changes the signature from const std::vector<cv::Mat>& to std::vector<cv::Mat>&
# and adds back tests that were removed in the bug.patch
# HEAD (701f77dce60f): Has non-const outs parameter, includes tests and <ade/util/zip_range.hpp>
# BASE (after bug.patch): Has const outs parameter, removes tests and <ade/util/zip_range.hpp>
# FIXED (after fix.patch): Restores non-const outs parameter, tests, and header
# Test file from /tests is copied to verify test changes

# Check 1: gcomputation.hpp should have non-const outs parameter
if grep -q '                     std::vector<cv::Mat>& outs' modules/gapi/include/opencv2/gapi/gcomputation.hpp; then
    echo "PASS: apply() has non-const outs parameter (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: apply() doesn't have non-const outs parameter (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gcomputation.cpp should have non-const outs parameter
if grep -q '                                   std::vector<cv::Mat> &outs' modules/gapi/src/api/gcomputation.cpp; then
    echo "PASS: Implementation has non-const outs parameter (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Implementation doesn't have non-const outs parameter (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gcomputation.cpp should directly use outs (not tmp copy)
if grep -q 'for (      cv::Mat &m : outs)' modules/gapi/src/api/gcomputation.cpp; then
    echo "PASS: Directly uses outs vector in cv::Mat version (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Doesn't directly use outs vector in cv::Mat version (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Test file should include <ade/util/zip_range.hpp>
if grep -q '#include <ade/util/zip_range.hpp>' modules/gapi/test/gapi_gcomputation_tests.cpp; then
    echo "PASS: Test includes <ade/util/zip_range.hpp> (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test doesn't include <ade/util/zip_range.hpp> (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Test file should have GComputationVectorMatsAsOutput fixture
if grep -q 'struct GComputationVectorMatsAsOutput' modules/gapi/test/gapi_gcomputation_tests.cpp; then
    echo "PASS: Test has GComputationVectorMatsAsOutput fixture (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test doesn't have GComputationVectorMatsAsOutput fixture (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test file should have OutputAllocated test
if grep -q 'TEST_F(GComputationVectorMatsAsOutput, OutputAllocated)' modules/gapi/test/gapi_gcomputation_tests.cpp; then
    echo "PASS: Test has OutputAllocated test case (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test doesn't have OutputAllocated test case (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Test file should have OutputNotAllocated test
if grep -q 'TEST_F(GComputationVectorMatsAsOutput, OutputNotAllocated)' modules/gapi/test/gapi_gcomputation_tests.cpp; then
    echo "PASS: Test has OutputNotAllocated test case (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test doesn't have OutputNotAllocated test case (BASE version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Test file should have OutputAllocatedWithInvalidMeta test
if grep -q 'TEST_F(GComputationVectorMatsAsOutput, OutputAllocatedWithInvalidMeta)' modules/gapi/test/gapi_gcomputation_tests.cpp; then
    echo "PASS: Test has OutputAllocatedWithInvalidMeta test case (HEAD version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test doesn't have OutputAllocatedWithInvalidMeta test case (BASE version)" >&2
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
