#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/photo/test"
cp "/tests/modules/photo/test/test_hdr.cpp" "modules/photo/test/test_hdr.cpp"

checks_passed=0
checks_failed=0

# PR #13362: The PR removes TonemapDurand from core OpenCV (moving to opencv_contrib)
# For harbor testing:
# - HEAD (742f22c09bd0c27b450f141bc984f280c8cde98e): TonemapDurand removed (fixed version)
# - BASE (after bug.patch): TonemapDurand still present (buggy version)
# - FIXED (after fix.patch): TonemapDurand removed again (back to HEAD)

# Check 1: photo.hpp should NOT have TonemapDurand class declaration
if grep -q 'class CV_EXPORTS_W TonemapDurand : public Tonemap' modules/photo/include/opencv2/photo.hpp; then
    echo "FAIL: photo.hpp still has TonemapDurand class (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: photo.hpp does not have TonemapDurand class (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 2: photo.hpp should NOT have createTonemapDurand function declaration
if grep -q 'createTonemapDurand' modules/photo/include/opencv2/photo.hpp; then
    echo "FAIL: photo.hpp still has createTonemapDurand function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: photo.hpp does not have createTonemapDurand function (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: tonemap.cpp should NOT have TonemapDurandImpl class
if grep -q 'class TonemapDurandImpl' modules/photo/src/tonemap.cpp; then
    echo "FAIL: tonemap.cpp still has TonemapDurandImpl class (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: tonemap.cpp does not have TonemapDurandImpl class (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: tonemap.cpp should NOT have createTonemapDurand implementation
if grep -q 'Ptr<TonemapDurand> createTonemapDurand' modules/photo/src/tonemap.cpp; then
    echo "FAIL: tonemap.cpp still has createTonemapDurand implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: tonemap.cpp does not have createTonemapDurand implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: test_hdr.cpp should NOT test TonemapDurand
if grep -q 'Ptr<TonemapDurand> durand' modules/photo/test/test_hdr.cpp; then
    echo "FAIL: test_hdr.cpp still tests TonemapDurand (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: test_hdr.cpp does not test TonemapDurand (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 6: opencv.bib should NOT have DD02 citation (Durand paper)
if grep -q '@inproceedings{DD02,' doc/opencv.bib; then
    echo "FAIL: opencv.bib still has DD02 citation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: opencv.bib does not have DD02 citation (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 7: Tutorial documentation should NOT mention TonemapDurand
if grep -q 'TonemapDurand' doc/tutorials/photo/hdr_imaging/hdr_imaging.markdown; then
    echo "FAIL: Tutorial still mentions TonemapDurand (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: Tutorial does not mention TonemapDurand (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 8: Python tutorial should NOT mention TonemapDurand
if grep -q 'createTonemapDurand' doc/py_tutorials/py_photo/py_hdr/py_hdr.markdown; then
    echo "FAIL: Python tutorial still mentions createTonemapDurand (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: Python tutorial does not mention createTonemapDurand (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 9: C++ sample should NOT use TonemapDurand
if grep -q 'TonemapDurand' samples/cpp/tutorial_code/photo/hdr_imaging/hdr_imaging.cpp; then
    echo "FAIL: C++ sample still uses TonemapDurand (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: C++ sample does not use TonemapDurand (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 10: Java sample should NOT use TonemapDurand
if grep -q 'TonemapDurand' samples/java/tutorial_code/photo/hdr_imaging/HDRImagingDemo.java; then
    echo "FAIL: Java sample still uses TonemapDurand (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: Java sample does not use TonemapDurand (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 11: Python sample should NOT use createTonemapDurand
if grep -q 'createTonemapDurand' samples/python/tutorial_code/photo/hdr_imaging/hdr_imaging.py; then
    echo "FAIL: Python sample still uses createTonemapDurand (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: Python sample does not use createTonemapDurand (fixed version)"
    checks_passed=$((checks_passed + 1))
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
