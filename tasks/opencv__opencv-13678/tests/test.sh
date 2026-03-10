#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_desc_tests.cpp" "modules/gapi/test/gapi_desc_tests.cpp"

checks_passed=0
checks_failed=0

# PR #13678 changes descr_of to return GMetaArgs instead of vector<GMatDesc>
# HEAD (1f4ad0a805eb5d39113ee88b37981da476adce9a): Fixed version with GMetaArgs
# BASE (after bug.patch): Buggy version with vector<GMatDesc>
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: gmat.hpp should declare descr_of returning GMetaArgs in gmetaarg.hpp, not vector<GMatDesc> in gmat.hpp
if ! grep -q 'GAPI_EXPORTS std::vector<GMatDesc> descr_of(const std::vector<cv::Mat> &vec)' modules/gapi/include/opencv2/gapi/gmat.hpp; then
    echo "PASS: gmat.hpp does not have vector<GMatDesc> descr_of for vector<Mat> (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.hpp has vector<GMatDesc> descr_of for vector<Mat> (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gmat.hpp should not declare descr_of for vector<UMat> returning vector<GMatDesc>
if ! grep -q 'GAPI_EXPORTS std::vector<GMatDesc> descr_of(const std::vector<cv::UMat> &vec)' modules/gapi/include/opencv2/gapi/gmat.hpp; then
    echo "PASS: gmat.hpp does not have vector<GMatDesc> descr_of for vector<UMat> (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.hpp has vector<GMatDesc> descr_of for vector<UMat> (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gmat.hpp should not declare descr_of for vector<own::Mat> returning vector<GMatDesc>
if ! grep -q 'GAPI_EXPORTS std::vector<GMatDesc> descr_of(const std::vector<Mat> &vec)' modules/gapi/include/opencv2/gapi/gmat.hpp; then
    echo "PASS: gmat.hpp does not have vector<GMatDesc> descr_of for vector<own::Mat> (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.hpp has vector<GMatDesc> descr_of for vector<own::Mat> (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: gmetaarg.hpp should have descr_of declarations returning GMetaArgs
if grep -q 'GAPI_EXPORTS cv::GMetaArgs descr_of(const std::vector<cv::Mat> &vec)' modules/gapi/include/opencv2/gapi/gmetaarg.hpp; then
    echo "PASS: gmetaarg.hpp has GMetaArgs descr_of for vector<Mat> (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmetaarg.hpp does not have GMetaArgs descr_of for vector<Mat> (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gmetaarg.hpp should have descr_of for vector<UMat> returning GMetaArgs
if grep -q 'GAPI_EXPORTS cv::GMetaArgs descr_of(const std::vector<cv::UMat> &vec)' modules/gapi/include/opencv2/gapi/gmetaarg.hpp; then
    echo "PASS: gmetaarg.hpp has GMetaArgs descr_of for vector<UMat> (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmetaarg.hpp does not have GMetaArgs descr_of for vector<UMat> (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: gmetaarg.hpp should have descr_of for vector<own::Mat> returning GMetaArgs
if grep -q 'GAPI_EXPORTS cv::GMetaArgs descr_of(const std::vector<Mat> &vec)' modules/gapi/include/opencv2/gapi/gmetaarg.hpp; then
    echo "PASS: gmetaarg.hpp has GMetaArgs descr_of for vector<own::Mat> (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmetaarg.hpp does not have GMetaArgs descr_of for vector<own::Mat> (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: gmat.cpp should have vec_descr_of returning GMetaArgs
if grep -q 'template <typename T> cv::GMetaArgs vec_descr_of(const std::vector<T> &vec)' modules/gapi/src/api/gmat.cpp; then
    echo "PASS: gmat.cpp has vec_descr_of returning GMetaArgs (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.cpp does not have vec_descr_of returning GMetaArgs (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gmat.cpp descr_of for vector<Mat> should return GMetaArgs
if grep -q 'cv::GMetaArgs cv::descr_of(const std::vector<cv::Mat> &vec)' modules/gapi/src/api/gmat.cpp; then
    echo "PASS: gmat.cpp descr_of for vector<Mat> returns GMetaArgs (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.cpp descr_of for vector<Mat> does not return GMetaArgs (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: gmat.cpp descr_of for vector<UMat> should return GMetaArgs
if grep -q 'cv::GMetaArgs cv::descr_of(const std::vector<cv::UMat> &vec)' modules/gapi/src/api/gmat.cpp; then
    echo "PASS: gmat.cpp descr_of for vector<UMat> returns GMetaArgs (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.cpp descr_of for vector<UMat> does not return GMetaArgs (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: gmat.cpp descr_of for vector<own::Mat> should return GMetaArgs
if grep -q 'cv::GMetaArgs cv::gapi::own::descr_of(const std::vector<cv::gapi::own::Mat> &vec)' modules/gapi/src/api/gmat.cpp; then
    echo "PASS: gmat.cpp descr_of for vector<own::Mat> returns GMetaArgs (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.cpp descr_of for vector<own::Mat> does not return GMetaArgs (buggy version)" >&2
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
