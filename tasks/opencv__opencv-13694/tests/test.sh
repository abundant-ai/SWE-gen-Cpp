#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/misc/python/test"
cp "/tests/modules/dnn/misc/python/test/test_dnn.py" "modules/dnn/misc/python/test/test_dnn.py"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_misc.cpp" "modules/dnn/test/test_misc.cpp"

checks_passed=0
checks_failed=0

# PR #13694 adds async inference API to OpenCV DNN module:
# 1. Adds AsyncMat typedef (std::future<Mat> wrapper)
# 2. Adds forwardAsync() method to Net class
# 3. Adds Python binding support for AsyncMat
# 4. Updates experimental namespace version from v11 to v12
# HEAD (53dbecf9009441ec2255c37a1cc390ab366ea13b): Fixed version with async API
# BASE (after bug.patch): Buggy version without async API
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: dnn.hpp should have AsyncMat typedef (fixed version)
if grep -q 'typedef std::future<Mat> AsyncMat' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has AsyncMat typedef (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp does not have AsyncMat typedef (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.hpp should have forwardAsync method declaration (fixed version)
if grep -q 'CV_WRAP AsyncMat forwardAsync' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has forwardAsync method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp does not have forwardAsync method (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.hpp should have experimental_dnn_34_v12 namespace (fixed version)
if grep -q 'namespace experimental_dnn_34_v12' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has experimental_dnn_34_v12 namespace (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp does not have experimental_dnn_34_v12 namespace (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn.hpp should NOT have experimental_dnn_34_v11 namespace (fixed version)
if ! grep -q 'namespace experimental_dnn_34_v11' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp does not have old experimental_dnn_34_v11 namespace (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp still has old experimental_dnn_34_v11 namespace (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: pyopencv_dnn.hpp should have chrono_milliseconds typedef (fixed version)
if grep -q 'typedef std::chrono::milliseconds chrono_milliseconds' modules/dnn/misc/python/pyopencv_dnn.hpp; then
    echo "PASS: pyopencv_dnn.hpp has chrono_milliseconds typedef (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_dnn.hpp does not have chrono_milliseconds typedef (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: pyopencv_dnn.hpp should have AsyncMatStatus typedef (fixed version)
if grep -q 'typedef std::future_status AsyncMatStatus' modules/dnn/misc/python/pyopencv_dnn.hpp; then
    echo "PASS: pyopencv_dnn.hpp has AsyncMatStatus typedef (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_dnn.hpp does not have AsyncMatStatus typedef (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: dnn.hpp should include <future> header (fixed version)
if grep -q '#include <future>' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp includes <future> header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp does not include <future> header (buggy version)" >&2
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
