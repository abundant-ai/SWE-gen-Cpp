#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test/ocl"
cp "/tests/modules/core/test/ocl/test_arithm.cpp" "modules/core/test/ocl/test_arithm.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_mat.cpp" "modules/core/test/test_mat.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_math.cpp" "modules/core/test/test_math.cpp"

checks_passed=0
checks_failed=0

# PR #13879 adds REDUCE_SUM2 operation to OpenCV's reduction API
# HEAD (b3d34c831ea8a373a253f81af7b0da6f3a250bd0): Fixed version with REDUCE_SUM2 support
# BASE (after bug.patch): Buggy version without REDUCE_SUM2 operation
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: REDUCE_SUM2 enum should exist in core.hpp (fixed version)
if grep -q 'REDUCE_SUM2 = 4' modules/core/include/opencv2/core.hpp; then
    echo "PASS: REDUCE_SUM2 enum defined in core.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: REDUCE_SUM2 enum not found in core.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: REDUCE_SUM2 documentation reference in reduce function description (fixed version)
if grep -q 'REDUCE_SUM2' modules/core/include/opencv2/core.hpp; then
    echo "PASS: REDUCE_SUM2 mentioned in core.hpp documentation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: REDUCE_SUM2 not mentioned in core.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: REDUCE_SUM2 implementation functions should exist (fixed version)
if grep -q 'reduceSum2R8u32s' modules/core/src/matrix_operations.cpp; then
    echo "PASS: REDUCE_SUM2 implementation functions exist in matrix_operations.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: REDUCE_SUM2 implementation functions missing from matrix_operations.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: OpAddSqr operation should exist in precomp.hpp (fixed version)
if grep -q 'struct OpAddSqr' modules/core/src/precomp.hpp; then
    echo "PASS: OpAddSqr operation exists in precomp.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpAddSqr operation missing from precomp.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: OpenCL support for REDUCE_SUM2 should exist (fixed version)
if grep -q 'OCL_CV_REDUCE_SUM2' modules/core/src/opencl/reduce2.cl; then
    echo "PASS: OpenCL support for REDUCE_SUM2 exists in reduce2.cl (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCL support for REDUCE_SUM2 missing from reduce2.cl (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: REDUCE_SUM2 validation should be in reduce function (fixed version)
if grep -q 'op == REDUCE_SUM2' modules/core/src/matrix_operations.cpp; then
    echo "PASS: REDUCE_SUM2 validation exists in reduce function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: REDUCE_SUM2 validation missing from reduce function (buggy version)" >&2
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
