#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/test_umat.py" "modules/python/test/test_umat.py"

checks_passed=0
checks_failed=0

# PR #12180: Refactor UMat Python bindings to use shadow headers
# The fix moves manual UMat wrapper code from cv2.cpp to generated bindings via shadow headers

# Check 1: pyopencv_umat.hpp should exist with UMat conversion macros
if [ -f "modules/core/misc/python/pyopencv_umat.hpp" ]; then
    echo "PASS: pyopencv_umat.hpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_umat.hpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: shadow_umat.hpp should exist with UMat class definition
if [ -f "modules/core/misc/python/shadow_umat.hpp" ]; then
    echo "PASS: shadow_umat.hpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shadow_umat.hpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: pyopencv_umat.hpp should have CV_PY_TO_CLASS macro
if grep -q 'CV_PY_TO_CLASS(UMat)' modules/core/misc/python/pyopencv_umat.hpp 2>/dev/null; then
    echo "PASS: pyopencv_umat.hpp has CV_PY_TO_CLASS macro"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_umat.hpp should have CV_PY_TO_CLASS macro" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: pyopencv_umat.hpp should have cv_UMat_queue function
if grep -q 'static void\* cv_UMat_queue()' modules/core/misc/python/pyopencv_umat.hpp 2>/dev/null; then
    echo "PASS: pyopencv_umat.hpp has cv_UMat_queue function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_umat.hpp should have cv_UMat_queue function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: pyopencv_umat.hpp should have cv_UMat_context function
if grep -q 'static void\* cv_UMat_context()' modules/core/misc/python/pyopencv_umat.hpp 2>/dev/null; then
    echo "PASS: pyopencv_umat.hpp has cv_UMat_context function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_umat.hpp should have cv_UMat_context function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: shadow_umat.hpp should have CV_WRAP_PHANTOM for queue
if grep -q 'CV_WRAP_PHANTOM(static void\* queue())' modules/core/misc/python/shadow_umat.hpp 2>/dev/null; then
    echo "PASS: shadow_umat.hpp has CV_WRAP_PHANTOM for queue"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shadow_umat.hpp should have CV_WRAP_PHANTOM for queue" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: shadow_umat.hpp should have CV_WRAP_PHANTOM for context
if grep -q 'CV_WRAP_PHANTOM(static void\* context())' modules/core/misc/python/shadow_umat.hpp 2>/dev/null; then
    echo "PASS: shadow_umat.hpp has CV_WRAP_PHANTOM for context"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shadow_umat.hpp should have CV_WRAP_PHANTOM for context" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: CMakeLists.txt should include shadow files in glob
if grep -q 'file(GLOB hdr ${OPENCV_MODULE_${m}_LOCATION}/misc/python/shadow\*\.hpp)' modules/python/bindings/CMakeLists.txt 2>/dev/null; then
    echo "PASS: CMakeLists.txt includes shadow files"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should include shadow files" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: cv2.cpp should NOT have manual UMatWrapper code (should be removed)
if ! grep -q 'typedef struct {' modules/python/src2/cv2.cpp | grep -q 'cv2_UMatWrapperObject' 2>/dev/null; then
    echo "PASS: cv2.cpp does not have manual UMatWrapper struct"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cv2.cpp should not have manual UMatWrapper struct" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: gen2.py should NOT check for phantom methods when calling instance methods
if grep -q 'if not v\.isphantom and ismethod and not self\.is_static:' modules/python/src2/gen2.py 2>/dev/null; then
    echo "PASS: gen2.py checks for phantom methods"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen2.py should check for phantom methods" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: gen2.py should avoid including shadow files in generated code
if grep -q "if hdr\.find('opencv2/') >= 0: #Avoid including the shadow files" modules/python/src2/gen2.py 2>/dev/null; then
    echo "PASS: gen2.py avoids including shadow files"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen2.py should avoid including shadow files" >&2
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
