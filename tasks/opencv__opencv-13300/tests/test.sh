#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/test_photo.js" "modules/js/test/test_photo.js"
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/tests.html" "modules/js/test/tests.html"
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/tests.js" "modules/js/test/tests.js"

checks_passed=0
checks_failed=0

# PR #13300: The PR adds photo module bindings to JavaScript
# For harbor testing:
# - HEAD (a5e7248119ffb52d3565fc6ecb972088a0863608): Photo module bindings exist (fixed version)
# - BASE (after bug.patch): Photo module bindings removed (buggy version)
# - FIXED (after fix.patch): Photo module bindings exist again (back to HEAD)

# Check 1: embindgen.py should have photo module definition
if grep -q "photo = {'': \['createAlignMTB', 'createCalibrateDebevec', 'createCalibrateRobertson'" modules/js/src/embindgen.py; then
    echo "PASS: embindgen.py has photo module definition (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: embindgen.py missing photo module definition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: embindgen.py should include photo in white_list
if grep -q "white_list = makeWhiteList(\[core, imgproc, objdetect, video, dnn, features2d, photo\])" modules/js/src/embindgen.py; then
    echo "PASS: embindgen.py includes photo in white_list (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: embindgen.py missing photo in white_list (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_photo.js should exist
if [ -f "modules/js/test/test_photo.js" ]; then
    echo "PASS: test_photo.js exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_photo.js does not exist (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tests.html should reference test_photo.js
if grep -q 'src="test_photo.js"' modules/js/test/tests.html; then
    echo "PASS: tests.html references test_photo.js (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tests.html missing test_photo.js reference (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: tests.js should include test_photo.js in test list
if grep -q "'test_photo.js'" modules/js/test/tests.js; then
    echo "PASS: tests.js includes test_photo.js (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tests.js missing test_photo.js (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: CMakeLists.txt should wrap photo module for js
if grep -q "ocv_define_module(photo opencv_imgproc OPTIONAL opencv_cudaarithm opencv_cudaimgproc WRAP java python js)" modules/photo/CMakeLists.txt; then
    echo "PASS: photo/CMakeLists.txt wraps js (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: photo/CMakeLists.txt does not wrap js (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: build_js.py should enable photo module
if grep -q '"-DBUILD_opencv_photo=ON"' platforms/js/build_js.py; then
    echo "PASS: build_js.py enables photo module (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: build_js.py does not enable photo module (buggy version)" >&2
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
