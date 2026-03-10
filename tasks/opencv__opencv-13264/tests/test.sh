#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/highgui/test"
cp "/tests/modules/highgui/test/test_gui.cpp" "modules/highgui/test/test_gui.cpp"

checks_passed=0
checks_failed=0

# PR #13264: The PR adds convertToShow helper function to support multiple image depths in imshow
# For harbor testing:
# - HEAD (db1c8b3f9ec7e59ae00664e03e2777d6a4ec44ca): convertToShow function exists (fixed version)
# - BASE (after bug.patch): convertToShow function removed (buggy version)
# - FIXED (after fix.patch): convertToShow function exists again (back to HEAD)

# Check 1: precomp.hpp should have convertToShow function definition
if grep -q "inline void convertToShow(const cv::Mat &src, cv::Mat &dst, bool toRGB = true)" modules/highgui/src/precomp.hpp; then
    echo "PASS: precomp.hpp has convertToShow function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: precomp.hpp missing convertToShow function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: precomp.hpp should have convertToShow overload
if grep -q "inline void convertToShow(const cv::Mat &src, const CvMat\* arr, bool toRGB = true)" modules/highgui/src/precomp.hpp; then
    echo "PASS: precomp.hpp has convertToShow overload (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: precomp.hpp missing convertToShow overload (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: window_QT.cpp should use convertToShow
if grep -q "convertToShow(cv::cvarrToMat(mat), image2Draw_mat);" modules/highgui/src/window_QT.cpp; then
    echo "PASS: window_QT.cpp uses convertToShow (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: window_QT.cpp does not use convertToShow (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: window_cocoa.mm should use convertToShow
if grep -q "convertToShow(arrMat, dst);" modules/highgui/src/window_cocoa.mm; then
    echo "PASS: window_cocoa.mm uses convertToShow (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: window_cocoa.mm does not use convertToShow (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: window_gtk.cpp should use convertToShow
if grep -q "convertToShow(cv::cvarrToMat(arr), widget->original_image);" modules/highgui/src/window_gtk.cpp; then
    echo "PASS: window_gtk.cpp uses convertToShow (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: window_gtk.cpp does not use convertToShow (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: window_w32.cpp should use convertToShow
if grep -q "convertToShow(cv::cvarrToMat(image), dst, false);" modules/highgui/src/window_w32.cpp; then
    echo "PASS: window_w32.cpp uses convertToShow (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: window_w32.cpp does not use convertToShow (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_gui.cpp should have the enhanced test with verify_size helper
if grep -q "inline void verify_size(const std::string &nm, const cv::Mat &img)" modules/highgui/test/test_gui.cpp; then
    echo "PASS: test_gui.cpp has verify_size helper (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_gui.cpp missing verify_size helper (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_gui.cpp should test multiple depths
if grep -q "const vector<int> depths = {CV_8U, CV_8S, CV_16U, CV_16S, CV_32F, CV_64F};" modules/highgui/test/test_gui.cpp; then
    echo "PASS: test_gui.cpp tests multiple depths (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_gui.cpp does not test multiple depths (buggy version)" >&2
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
