#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_webp.cpp" "modules/imgcodecs/test/test_webp.cpp"

checks_passed=0
checks_failed=0

# PR #12353: Refactor WebP decoder from C FILE API to C++ fstream
# For harbor testing:
# - HEAD (0515f930e87f2817dc40674913cc696558489ddf): Fixed version using C++ fstream
# - BASE (after bug.patch): Buggy old version using C FILE API (fopen/fread)
# - FIXED (after oracle applies fix): Back to fixed version with C++ fstream
#
# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: grfmt_webp.cpp should use C++ fstream (fs.open) instead of FILE API (fixed version)
if grep -q 'fs.open(m_filename.c_str(), std::ios::binary);' modules/imgcodecs/src/grfmt_webp.cpp && \
   grep -q 'fs.read' modules/imgcodecs/src/grfmt_webp.cpp; then
    echo "PASS: grfmt_webp.cpp uses C++ fstream - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_webp.cpp should use C++ fstream instead of C FILE API - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: grfmt_webp.hpp should include <fstream> (fixed version)
if grep -q '#include <fstream>' modules/imgcodecs/src/grfmt_webp.hpp; then
    echo "PASS: grfmt_webp.hpp includes fstream - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_webp.hpp should include fstream - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: grfmt_webp.hpp should have fs member variable (fixed version)
if grep -q 'std::ifstream fs;' modules/imgcodecs/src/grfmt_webp.hpp; then
    echo "PASS: grfmt_webp.hpp has ifstream fs member - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_webp.hpp should have ifstream fs member - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: grfmt_webp.cpp should have WEBP_HEADER_SIZE as static const (fixed version)
if grep -q 'static const size_t WEBP_HEADER_SIZE = 32;' modules/imgcodecs/src/grfmt_webp.cpp; then
    echo "PASS: grfmt_webp.cpp has WEBP_HEADER_SIZE as static const - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_webp.cpp should have WEBP_HEADER_SIZE as static const - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: grfmt_webp.cpp should have param_maxFileSize (fixed version)
if grep -q 'param_maxFileSize' modules/imgcodecs/src/grfmt_webp.cpp; then
    echo "PASS: grfmt_webp.cpp has param_maxFileSize - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_webp.cpp should have param_maxFileSize - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: loadsave.cpp should have try-catch around encoder->write (fixed version)
if grep -q 'try' modules/imgcodecs/src/loadsave.cpp && \
   grep -q "imwrite_('" modules/imgcodecs/src/loadsave.cpp; then
    echo "PASS: loadsave.cpp has try-catch around encoder->write - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: loadsave.cpp should have try-catch around encoder->write - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_webp.cpp should have both img_webp and img_webp_bgr variables (fixed version)
if grep -q 'cv::Mat img_webp = cv::imread(output, IMREAD_UNCHANGED);' modules/imgcodecs/test/test_webp.cpp && \
   grep -q 'cv::Mat img_webp_bgr = cv::imread(output);' modules/imgcodecs/test/test_webp.cpp; then
    echo "PASS: test_webp.cpp has both img_webp and img_webp_bgr - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_webp.cpp should have both img_webp and img_webp_bgr variables - buggy version" >&2
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
