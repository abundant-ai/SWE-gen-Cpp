#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/objdetect/test"
cp "/tests/modules/objdetect/test/test_qrcode.cpp" "modules/objdetect/test/test_qrcode.cpp"

checks_passed=0
checks_failed=0

# PR #13097: QRCodeDetector API improvements
# For harbor testing:
# - HEAD (82e8657a6dc22077612f02363ba78f67f1b978ae): Fixed version with full API
# - BASE (after bug.patch): Buggy version with minimal API
# - FIXED (after fix.patch): Back to fixed version

# Check 1: objdetect.hpp should have CV_EXPORTS_W decorator on QRCodeDetector class
if grep -q "class CV_EXPORTS_W QRCodeDetector" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has CV_EXPORTS_W on QRCodeDetector - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing CV_EXPORTS_W - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: objdetect.hpp should have CV_WRAP on QRCodeDetector constructor
if grep -q "CV_WRAP QRCodeDetector();" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has CV_WRAP on constructor - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing CV_WRAP on constructor - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: objdetect.hpp should have detectAndDecode method
if grep -q "CV_WRAP cv::String detectAndDecode" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has detectAndDecode method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing detectAndDecode method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: objdetect.hpp should have decode method with documentation
if grep -q "CV_WRAP cv::String decode" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has decode method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing decode method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: qrcode.cpp should have QRCodeDetector::decode implementation
if grep -q "cv::String QRCodeDetector::decode" modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp has QRCodeDetector::decode implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp missing QRCodeDetector::decode - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: qrcode.cpp should have QRCodeDetector::detectAndDecode implementation
if grep -q "cv::String QRCodeDetector::detectAndDecode" modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp has QRCodeDetector::detectAndDecode implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp missing QRCodeDetector::detectAndDecode - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_qrcode.cpp should use QRCodeDetector class API
if grep -q "QRCodeDetector qrcode;" modules/objdetect/test/test_qrcode.cpp; then
    echo "PASS: test_qrcode.cpp uses QRCodeDetector class - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_qrcode.cpp doesn't use QRCodeDetector class - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_qrcode.cpp should use detectAndDecode method
if grep -q "qrcode.detectAndDecode" modules/objdetect/test/test_qrcode.cpp; then
    echo "PASS: test_qrcode.cpp uses detectAndDecode method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_qrcode.cpp doesn't use detectAndDecode - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: perf_qrcode_pipeline.cpp should use QRCodeDetector class
if grep -q "QRCodeDetector qrcode;" modules/objdetect/perf/perf_qrcode_pipeline.cpp; then
    echo "PASS: perf_qrcode_pipeline.cpp uses QRCodeDetector class - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_qrcode_pipeline.cpp doesn't use QRCodeDetector class - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: qrcode.cpp detect method should handle color conversion
if grep -q "cvtColor(inarr, gray, COLOR_BGR2GRAY);" modules/objdetect/src/qrcode.cpp; then
    echo "PASS: qrcode.cpp detect method handles color conversion - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: qrcode.cpp detect method missing color conversion - buggy version" >&2
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
