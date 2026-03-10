#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/test_features2d.js" "modules/js/test/test_features2d.js"
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/tests.html" "modules/js/test/tests.html"
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/tests.js" "modules/js/test/tests.js"

checks_passed=0
checks_failed=0

# PR #12855: Add conditional compilation guards for JS bindings
# For harbor testing:
# - HEAD (8ecc5e6f6464b37aedd48eed9777262b7f4aa1ae): Fixed version with #ifdef guards
# - BASE (after bug.patch): Buggy version without #ifdef guards
# - FIXED (after fix.patch): Back to fixed version

# Check 1: core_bindings.cpp should have HAVE_OPENCV_DNN guard
if grep -q '#ifdef HAVE_OPENCV_DNN' modules/js/src/core_bindings.cpp && \
   grep -A1 '#ifdef HAVE_OPENCV_DNN' modules/js/src/core_bindings.cpp | grep -q 'using namespace dnn;'; then
    echo "PASS: core_bindings.cpp has HAVE_OPENCV_DNN guard - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core_bindings.cpp missing HAVE_OPENCV_DNN guard - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: core_bindings.cpp should have HAVE_OPENCV_IMGPROC guard for minEnclosingCircle
if grep -B1 'Circle minEnclosingCircle' modules/js/src/core_bindings.cpp | grep -q '#ifdef HAVE_OPENCV_IMGPROC'; then
    echo "PASS: core_bindings.cpp has HAVE_OPENCV_IMGPROC guard for minEnclosingCircle - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core_bindings.cpp missing HAVE_OPENCV_IMGPROC guard for minEnclosingCircle - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: core_bindings.cpp should have HAVE_OPENCV_VIDEO guard for CamShiftWrapper
if grep -B1 'emscripten::val CamShiftWrapper' modules/js/src/core_bindings.cpp | grep -q '#ifdef HAVE_OPENCV_VIDEO'; then
    echo "PASS: core_bindings.cpp has HAVE_OPENCV_VIDEO guard for CamShiftWrapper - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core_bindings.cpp missing HAVE_OPENCV_VIDEO guard for CamShiftWrapper - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: core_bindings.cpp should have HAVE_OPENCV_IMGPROC guard for minEnclosingCircle binding
if grep -B1 'function("minEnclosingCircle"' modules/js/src/core_bindings.cpp | grep -q '#ifdef HAVE_OPENCV_IMGPROC'; then
    echo "PASS: core_bindings.cpp has HAVE_OPENCV_IMGPROC guard for minEnclosingCircle binding - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core_bindings.cpp missing HAVE_OPENCV_IMGPROC guard for minEnclosingCircle binding - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: core_bindings.cpp should have HAVE_OPENCV_VIDEO guard for CamShift binding
if grep -B1 'function("CamShift"' modules/js/src/core_bindings.cpp | grep -q '#ifdef HAVE_OPENCV_VIDEO'; then
    echo "PASS: core_bindings.cpp has HAVE_OPENCV_VIDEO guard for CamShift binding - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: core_bindings.cpp missing HAVE_OPENCV_VIDEO guard for CamShift binding - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: embindgen.py should NOT have FAST and AGAST in fixed version (removed from exports)
if grep -q "'': \['drawKeypoints', 'drawMatches'\]" modules/js/src/embindgen.py && \
   ! grep -q "'': \['FAST', 'AGAST'," modules/js/src/embindgen.py; then
    echo "PASS: embindgen.py has FAST and AGAST removed from exports - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: embindgen.py still has FAST and AGAST in exports - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: build_js.py should have -DWITH_QUIRC=OFF flag
if grep -q '"-DWITH_QUIRC=OFF"' platforms/js/build_js.py; then
    echo "PASS: build_js.py has -DWITH_QUIRC=OFF flag - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: build_js.py missing -DWITH_QUIRC=OFF flag - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: build_js.py should have -DBUILD_opencv_java_bindings_generator=OFF flag
if grep -q '"-DBUILD_opencv_java_bindings_generator=OFF"' platforms/js/build_js.py; then
    echo "PASS: build_js.py has -DBUILD_opencv_java_bindings_generator=OFF flag - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: build_js.py missing -DBUILD_opencv_java_bindings_generator=OFF flag - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: build_js.py should have -DBUILD_opencv_python_bindings_generator=OFF flag
if grep -q '"-DBUILD_opencv_python_bindings_generator=OFF"' platforms/js/build_js.py; then
    echo "PASS: build_js.py has -DBUILD_opencv_python_bindings_generator=OFF flag - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: build_js.py missing -DBUILD_opencv_python_bindings_generator=OFF flag - buggy version" >&2
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
