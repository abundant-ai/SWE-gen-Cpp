#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/objdetect/test"
cp "/tests/modules/objdetect/test/test_qrcode.cpp" "modules/objdetect/test/test_qrcode.cpp"

checks_passed=0
checks_failed=0

# PR #13086: QRCodeDetector API improvements for consistent detect/decode workflow
# For harbor testing:
# - HEAD (80814026c3d26c86888fd321c29fa6f2f0795e87): Fixed version with full class API
# - BASE (after bug.patch): Buggy version with standalone functions
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

# Check 3: objdetect.hpp should have CV_WRAP on setEpsX method
if grep -q "CV_WRAP void setEpsX(double epsX);" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has CV_WRAP on setEpsX - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing CV_WRAP on setEpsX - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: objdetect.hpp should have CV_WRAP on setEpsY method
if grep -q "CV_WRAP void setEpsY(double epsY);" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has CV_WRAP on setEpsY - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing CV_WRAP on setEpsY - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: objdetect.hpp should have detect method with CV_WRAP
if grep -q "CV_WRAP bool detect(InputArray img, OutputArray points) const;" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has CV_WRAP detect method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing CV_WRAP detect method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: objdetect.hpp should have decode method with documentation
if grep -q "CV_WRAP std::string decode(InputArray img, InputArray points, OutputArray straight_qrcode = noArray());" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has decode method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing decode method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: objdetect.hpp should have detectAndDecode method
if grep -q "CV_WRAP std::string detectAndDecode(InputArray img, OutputArray points=noArray()," modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "PASS: objdetect.hpp has detectAndDecode method - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: objdetect.hpp missing detectAndDecode method - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: objdetect.hpp should NOT have standalone detectQRCode function (buggy version has it)
if grep -q "CV_EXPORTS bool detectQRCode(InputArray in, std::vector<Point> &points" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "FAIL: objdetect.hpp has standalone detectQRCode function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: objdetect.hpp doesn't have standalone detectQRCode - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 9: objdetect.hpp should NOT have standalone decodeQRCode function (buggy version has it)
if grep -q "CV_EXPORTS bool decodeQRCode(InputArray in, InputArray points, std::string &decoded_info" modules/objdetect/include/opencv2/objdetect.hpp; then
    echo "FAIL: objdetect.hpp has standalone decodeQRCode function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: objdetect.hpp doesn't have standalone decodeQRCode - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 10: perf_qrcode_pipeline.cpp should use QRCodeDetector class
if grep -q "QRCodeDetector qrcode;" modules/objdetect/perf/perf_qrcode_pipeline.cpp; then
    echo "PASS: perf_qrcode_pipeline.cpp uses QRCodeDetector class - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_qrcode_pipeline.cpp doesn't use QRCodeDetector class - buggy version" >&2
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
