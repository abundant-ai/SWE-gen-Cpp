#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/objdetect/test"
cp "/tests/modules/objdetect/test/test_qrcode.cpp" "modules/objdetect/test/test_qrcode.cpp"

checks_passed=0
checks_failed=0

# PR #12204: Fix QR code detector corner localization regression
# The fix renames QRDecode to QRDetect, changes searchVerticalLines to searchHorizontalLines,
# and improves the detection algorithm

# Check 1: Class should be named QRDetect (not QRDecode)
if grep -q 'class QRDetect' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp uses class QRDetect"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp should use class QRDetect (not QRDecode)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: init method should take const Mat& reference
if grep -q 'void init(const Mat& src, double eps_vertical_ = 0.2, double eps_horizontal_ = 0.1)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: QRDetect::init takes const Mat& reference"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDetect::init should take const Mat& reference" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Method should be named computeTransformationPoints (not transformation)
if grep -q 'bool computeTransformationPoints();' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp declares computeTransformationPoints method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp should declare computeTransformationPoints method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Should have searchHorizontalLines method (not searchVerticalLines)
if grep -q 'vector<Vec3d> searchHorizontalLines();' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp declares searchHorizontalLines method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp should declare searchHorizontalLines method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Should have separateVerticalLines method (not separateHorizontalLines)
if grep -q 'vector<Point2f> separateVerticalLines(const vector<Vec3d> &list_lines);' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp declares separateVerticalLines method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp should declare separateVerticalLines method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: init implementation should use CV_Assert
if grep -q 'CV_Assert(!src.empty())' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: QRDetect::init has CV_Assert check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDetect::init should have CV_Assert check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: init should use const double min_side
if grep -q 'const double min_side = std::min(src.size().width, src.size().height)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: QRDetect::init uses const double min_side"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDetect::init should use const double min_side" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: init should use cvRound instead of static_cast<int>
if grep -q 'const int width  = cvRound(src.size().width  \* coeff_expansion)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: QRDetect::init uses cvRound for width"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDetect::init should use cvRound for width" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: init should use cvRound for height
if grep -q 'const int height = cvRound(src.size().height  \* coeff_expansion)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: QRDetect::init uses cvRound for height"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDetect::init should use cvRound for height" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: resize should include INTER_LINEAR parameter
if grep -q 'resize(src, barcode, new_size, 0, 0, INTER_LINEAR)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: resize call includes INTER_LINEAR parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: resize call should include INTER_LINEAR parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: adaptiveThreshold should use threshold value 83 (not 71)
if grep -q 'adaptiveThreshold(barcode, bin_barcode, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 83, 2)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: adaptiveThreshold uses threshold value 83"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: adaptiveThreshold should use threshold value 83" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: searchHorizontalLines implementation should exist
if grep -q 'vector<Vec3d> QRDetect::searchHorizontalLines()' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: QRDetect::searchHorizontalLines implementation exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDetect::searchHorizontalLines implementation should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: searchHorizontalLines should use const int height_bin_barcode
if grep -A 5 'vector<Vec3d> QRDetect::searchHorizontalLines()' modules/objdetect/src/qrcode.cpp | grep -q 'const int height_bin_barcode = bin_barcode.rows'; then
    echo "PASS: searchHorizontalLines uses const int height_bin_barcode"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: searchHorizontalLines should use const int height_bin_barcode" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: searchHorizontalLines should use const int width_bin_barcode
if grep -A 6 'vector<Vec3d> QRDetect::searchHorizontalLines()' modules/objdetect/src/qrcode.cpp | grep -q 'const int width_bin_barcode  = bin_barcode.cols'; then
    echo "PASS: searchHorizontalLines uses const int width_bin_barcode"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: searchHorizontalLines should use const int width_bin_barcode" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: searchHorizontalLines should iterate over y (rows), not x
if grep -q 'for (int y = 0; y < height_bin_barcode; y++)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: searchHorizontalLines iterates over y (rows)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: searchHorizontalLines should iterate over y (rows)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: Should use bin_barcode.ptr<uint8_t>(y) for row access
if grep -q 'const uint8_t \*bin_barcode_row = bin_barcode.ptr<uint8_t>(y)' modules/objdetect/src/qrcode.cpp; then
    echo "PASS: Uses bin_barcode.ptr<uint8_t>(y) for efficient row access"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Should use bin_barcode.ptr<uint8_t>(y) for efficient row access" >&2
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
