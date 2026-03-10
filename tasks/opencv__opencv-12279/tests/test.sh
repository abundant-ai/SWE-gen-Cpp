#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/objdetect/misc/java/test"
cp "/tests/modules/objdetect/misc/java/test/CascadeClassifierTest.java" "modules/objdetect/misc/java/test/CascadeClassifierTest.java"

checks_passed=0
checks_failed=0

# PR #12279: Fix Java test for CascadeDetect by adding equalizeHist
# The fix also corrects RGB2Gray conversion by using proper gray_shift coefficients
# For harbor testing:
# - HEAD (cc112ce6c7e45a3f72821f7dd0ec547180eef2bc): Fixed version with equalizeHist and correct RGB2Gray
# - BASE (after bug.patch): Buggy version without proper gray conversion
# - FIXED (after oracle applies fix): Back to fixed version

# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: color.hpp should have gray_shift = 15 (fixed version)
if grep -q 'gray_shift = 15' modules/imgproc/src/color.hpp; then
    echo "PASS: color.hpp has gray_shift = 15 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: color.hpp should have gray_shift = 15 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: color.hpp should have RY15, GY15, BY15 constants (fixed version)
if grep -q 'RY15 =  9798' modules/imgproc/src/color.hpp && \
   grep -q 'GY15 = 19235' modules/imgproc/src/color.hpp && \
   grep -q 'BY15 =  3735' modules/imgproc/src/color.hpp; then
    echo "PASS: color.hpp has RY15/GY15/BY15 constants - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: color.hpp should have RY15/GY15/BY15 constants - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: color_rgb.cpp should use RY15/GY15/BY15 coefficients (fixed version)
if grep -q 'const int coeffs0\[\] = { RY15, GY15, BY15 }' modules/imgproc/src/color_rgb.cpp; then
    echo "PASS: color_rgb.cpp uses RY15/GY15/BY15 coefficients - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: color_rgb.cpp should use RY15/GY15/BY15 coefficients - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: color_rgb.cpp should use gray_shift (fixed version)
if grep -q 'int b = 0, g = 0, r = (1 << (gray_shift-1))' modules/imgproc/src/color_rgb.cpp && \
   grep -q 'dst\[i\] = (uchar)((_tab\[src\[0\]\] + _tab\[src\[1\]+256\] + _tab\[src\[2\]+512\]) >> gray_shift)' modules/imgproc/src/color_rgb.cpp; then
    echo "PASS: color_rgb.cpp uses gray_shift - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: color_rgb.cpp should use gray_shift - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: opencl/color_rgb.cl should have gray_shift and RY15/GY15/BY15 (fixed version)
if grep -q 'gray_shift = 15' modules/imgproc/src/opencl/color_rgb.cl && \
   grep -q 'RY15 = 9798' modules/imgproc/src/opencl/color_rgb.cl && \
   grep -q 'GY15 = 19235' modules/imgproc/src/opencl/color_rgb.cl && \
   grep -q 'BY15 = 3735' modules/imgproc/src/opencl/color_rgb.cl; then
    echo "PASS: opencl/color_rgb.cl has gray_shift and RY15/GY15/BY15 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencl/color_rgb.cl should have gray_shift and RY15/GY15/BY15 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: opencl/color_rgb.cl should have DEPTH_0 branch with gray_shift (fixed version)
if grep -q '#elif defined(DEPTH_0)' modules/imgproc/src/opencl/color_rgb.cl && \
   grep -q 'mad24(src_pix.B_COMP, BY15, mad24(src_pix.G_COMP, GY15, mul24(src_pix.R_COMP, RY15))), gray_shift' modules/imgproc/src/opencl/color_rgb.cl; then
    echo "PASS: opencl/color_rgb.cl has DEPTH_0 branch with gray_shift - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencl/color_rgb.cl should have DEPTH_0 branch with gray_shift - buggy version" >&2
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
