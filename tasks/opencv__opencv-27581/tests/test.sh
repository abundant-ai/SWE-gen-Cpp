#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/test_cuda.py" "modules/python/test/test_cuda.py"

checks_passed=0
checks_failed=0

# Check 1: DLPack header inclusion in pyopencv_core.hpp (fixed version)
if grep -q '#include "dlpack/dlpack.h"' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp includes DLPack header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing DLPack header (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: DLPack capsule name definition (fixed version)
if grep -q 'CV_DLPACK_CAPSULE_NAME' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp defines DLPack capsule name (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing DLPack capsule name (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: fillDLPackTensor template function (fixed version)
if grep -q 'fillDLPackTensor' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp contains fillDLPackTensor template (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing fillDLPackTensor template (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: to_dlpack function (fixed version)
if grep -q 'to_dlpack' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp contains to_dlpack function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing to_dlpack function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: from_dlpack function (fixed version)
if grep -q 'from_dlpack' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp contains from_dlpack function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing from_dlpack function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: GpuMat DLPack implementation in pyopencv_cuda.hpp (fixed version)
if grep -q 'fillDLPackTensor.*GpuMat' modules/core/misc/python/pyopencv_cuda.hpp; then
    echo "PASS: pyopencv_cuda.hpp contains GpuMat DLPack implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_cuda.hpp missing GpuMat DLPack implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: pyDLPackGpuMat Python binding (fixed version)
if grep -q 'pyDLPackGpuMat' modules/core/misc/python/pyopencv_cuda.hpp; then
    echo "PASS: pyopencv_cuda.hpp contains pyDLPackGpuMat binding (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_cuda.hpp missing pyDLPackGpuMat binding (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: PYOPENCV_EXTRA_METHODS_cuda_GpuMat macro (fixed version)
if grep -q 'PYOPENCV_EXTRA_METHODS_cuda_GpuMat' modules/core/misc/python/pyopencv_cuda.hpp; then
    echo "PASS: pyopencv_cuda.hpp defines extra methods macro for GpuMat (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_cuda.hpp missing extra methods macro (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_dlpack_GpuMat test function in test file (fixed version)
if grep -q 'def test_dlpack_GpuMat' modules/python/test/test_cuda.py; then
    echo "PASS: test_cuda.py contains test_dlpack_GpuMat test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_cuda.py missing test_dlpack_GpuMat test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: from_dlpack call in test (fixed version)
if grep -q 'from_dlpack' modules/python/test/test_cuda.py; then
    echo "PASS: test_cuda.py uses from_dlpack (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_cuda.py missing from_dlpack usage (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: gen2.py includes PYOPENCV_EXTRA_METHODS (fixed version)
if grep -q 'PYOPENCV_EXTRA_METHODS_' modules/python/src2/gen2.py; then
    echo "PASS: gen2.py includes extra methods support (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen2.py missing extra methods support (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: DLPack cmake detection (fixed version)
if grep -q 'OpenCVDetectDLPack' CMakeLists.txt; then
    echo "PASS: CMakeLists.txt includes DLPack detection (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt missing DLPack detection (buggy version)" >&2
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
