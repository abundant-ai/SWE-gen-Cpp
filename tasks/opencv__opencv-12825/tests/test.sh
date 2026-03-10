#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_arithm.cpp" "modules/core/test/test_arithm.cpp"

checks_passed=0
checks_failed=0

# PR #12825: Add tests for division by zero + restore DEPTH_dst defines
# For harbor testing:
# - HEAD (5677a683a55dc64e0f47a7a61d88253a1a6b2f9e): Fixed version WITH DEPTH_dst defines + divide tests
# - BASE (after bug.patch): Buggy version WITHOUT DEPTH_dst or divide tests
# - FIXED (after oracle applies fix): Back to fixed version WITH DEPTH_dst + divide tests

# Check 1: arithm.cpp SHOULD use DEPTH_dst (fixed version has it)
if grep -q 'DEPTH_dst' modules/core/src/arithm.cpp; then
    echo "PASS: arithm.cpp uses DEPTH_dst - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cpp missing DEPTH_dst - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: convert_scale.cpp SHOULD use DEPTH_dst (fixed version has it)
if grep -q 'DEPTH_dst' modules/core/src/convert_scale.cpp; then
    echo "PASS: convert_scale.cpp uses DEPTH_dst - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convert_scale.cpp missing DEPTH_dst - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: mathfuncs.cpp SHOULD use DEPTH_dst (fixed version has it)
if grep -q 'DEPTH_dst' modules/core/src/mathfuncs.cpp; then
    echo "PASS: mathfuncs.cpp uses DEPTH_dst - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mathfuncs.cpp missing DEPTH_dst - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: matmul.cpp SHOULD use DEPTH_dst (fixed version has it)
if grep -q 'DEPTH_dst' modules/core/src/matmul.cpp; then
    echo "PASS: matmul.cpp uses DEPTH_dst - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: matmul.cpp missing DEPTH_dst - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: arithm.cl SHOULD have DEPTH_dst error checking (fixed version has it)
if grep -q '#if !defined(DEPTH_dst)' modules/core/src/opencl/arithm.cl; then
    echo "PASS: arithm.cl has DEPTH_dst error checking - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cl missing DEPTH_dst error checking - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: arithm.cl SHOULD define CV_DST_TYPE_IS_INTEGER (fixed version has it)
if grep -q '#define CV_DST_TYPE_IS_INTEGER' modules/core/src/opencl/arithm.cl; then
    echo "PASS: arithm.cl defines CV_DST_TYPE_IS_INTEGER - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cl missing CV_DST_TYPE_IS_INTEGER - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: arithm.cl SHOULD define CV_DST_TYPE_FIT_32F (fixed version has it)
if grep -q '#define CV_DST_TYPE_FIT_32F' modules/core/src/opencl/arithm.cl; then
    echo "PASS: arithm.cl defines CV_DST_TYPE_FIT_32F - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cl missing CV_DST_TYPE_FIT_32F - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: arithm.cl SHOULD use CV_DST_TYPE_FIT_32F (fixed version has it, buggy uses 'depth')
if grep -q '#if CV_DST_TYPE_FIT_32F' modules/core/src/opencl/arithm.cl; then
    echo "PASS: arithm.cl uses CV_DST_TYPE_FIT_32F - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: arithm.cl uses 'depth' instead - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: arithm.cl SHOULD NOT use 'depth <= 5' for PI (buggy version has it)
if grep -q '#if depth <= 5' modules/core/src/opencl/arithm.cl; then
    echo "FAIL: arithm.cl uses 'depth <= 5' - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: arithm.cl uses CV_DST_TYPE_FIT_32F instead of 'depth' - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 10: test_arithm.cpp SHOULD have divide by zero tests (fixed version has them)
if grep -q 'TEST(Core_DivideRules, type_64f)' modules/core/test/test_arithm.cpp; then
    echo "PASS: test_arithm.cpp has divide-by-zero tests - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_arithm.cpp missing divide-by-zero tests - buggy version" >&2
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
