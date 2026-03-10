#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/objdetect/test"
cp "/tests/modules/objdetect/test/test_qrcode.cpp" "modules/objdetect/test/test_qrcode.cpp"

checks_passed=0
checks_failed=0

# PR #11921: Fix QR code detection for better corner localization

# Check 1: QRCodeDetector class should exist in objdetect.hpp
if grep -q 'class CV_EXPORTS QRCodeDetector' modules/objdetect/include/opencv2/objdetect.hpp 2>/dev/null && \
   grep -q 'void setEpsX(double epsX);' modules/objdetect/include/opencv2/objdetect.hpp 2>/dev/null && \
   grep -q 'void setEpsY(double epsY);' modules/objdetect/include/opencv2/objdetect.hpp 2>/dev/null; then
    echo "PASS: QRCodeDetector class is defined in objdetect.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRCodeDetector class should be defined in objdetect.hpp with setEpsX/setEpsY methods" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: QRDecode should use Point2f for transformation points
if grep -q 'vector<Point2f> getTransformationPoints()' modules/objdetect/src/qrcode.cpp 2>/dev/null && \
   grep -q 'vector<Point2f> localization_points, transformation_points;' modules/objdetect/src/qrcode.cpp 2>/dev/null; then
    echo "PASS: QRDecode uses Point2f for transformation points"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDecode should use Point2f (not Point) for transformation points" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: QRDecode init should have updated epsilon values (0.2 and 0.1)
if grep -q 'void init(Mat src, double eps_vertical_ = 0.2, double eps_horizontal_ = 0.1);' modules/objdetect/src/qrcode.cpp 2>/dev/null; then
    echo "PASS: QRDecode init uses updated epsilon values (0.2, 0.1)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDecode init should use eps_vertical=0.2 and eps_horizontal=0.1" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: QRDecode should have coeff_expansion and image resizing logic
if grep -q 'double min_side = std::min(src.size().width, src.size().height);' modules/objdetect/src/qrcode.cpp 2>/dev/null && \
   grep -q 'coeff_expansion = 512.0 / min_side;' modules/objdetect/src/qrcode.cpp 2>/dev/null && \
   grep -q 'resize(src, barcode, new_size);' modules/objdetect/src/qrcode.cpp 2>/dev/null; then
    echo "PASS: QRDecode has image resizing logic with coeff_expansion"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDecode should have image resizing logic for images smaller than 512 pixels" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: QRDecode should have computeTransformationPoints method
if grep -q 'bool computeTransformationPoints();' modules/objdetect/src/qrcode.cpp 2>/dev/null; then
    echo "PASS: QRDecode has computeTransformationPoints method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDecode should have computeTransformationPoints method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: QRDecode should have testBypassRoute and getTriangleArea methods
if grep -q 'bool testBypassRoute(vector<Point2f> hull, int start, int finish);' modules/objdetect/src/qrcode.cpp 2>/dev/null && \
   grep -q 'double getTriangleArea(Point2f a, Point2f b, Point2f c);' modules/objdetect/src/qrcode.cpp 2>/dev/null; then
    echo "PASS: QRDecode has testBypassRoute and getTriangleArea methods"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: QRDecode should have testBypassRoute and getTriangleArea helper methods" >&2
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
