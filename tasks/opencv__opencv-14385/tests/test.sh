#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin_utils.hpp" "modules/core/test/test_intrin_utils.hpp"

checks_passed=0
checks_failed=0

# Check 1: test_intrin_utils.hpp should have test_reduce_sad() method definition (fixed version)
if grep -q 'TheTest & test_reduce_sad()' modules/core/test/test_intrin_utils.hpp; then
    echo "PASS: test_intrin_utils.hpp has test_reduce_sad() method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_intrin_utils.hpp missing test_reduce_sad() method (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: test_hal_intrin_uint8() should call test_reduce_sad() (fixed version)
if grep -A 30 'void test_hal_intrin_uint8()' modules/core/test/test_intrin_utils.hpp | grep -q '\.test_reduce_sad()'; then
    echo "PASS: test_hal_intrin_uint8() calls test_reduce_sad() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_hal_intrin_uint8() missing test_reduce_sad() call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_hal_intrin_int8() should call test_reduce_sad() (fixed version)
if grep -A 30 'void test_hal_intrin_int8()' modules/core/test/test_intrin_utils.hpp | grep -q '\.test_reduce_sad()'; then
    echo "PASS: test_hal_intrin_int8() calls test_reduce_sad() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_hal_intrin_int8() missing test_reduce_sad() call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_hal_intrin_uint16() should call test_reduce_sad() (fixed version)
if grep -A 30 'void test_hal_intrin_uint16()' modules/core/test/test_intrin_utils.hpp | grep -q '\.test_reduce_sad()'; then
    echo "PASS: test_hal_intrin_uint16() calls test_reduce_sad() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_hal_intrin_uint16() missing test_reduce_sad() call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_hal_intrin_int16() should call test_reduce_sad() (fixed version)
if grep -A 30 'void test_hal_intrin_int16()' modules/core/test/test_intrin_utils.hpp | grep -q '\.test_reduce_sad()'; then
    echo "PASS: test_hal_intrin_int16() calls test_reduce_sad() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_hal_intrin_int16() missing test_reduce_sad() call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: intrin_avx.hpp should have correct v_reduce_sad for v_uint8x32 (fixed version has multi-line reduction)
if grep -A 3 'inline unsigned v_reduce_sad(const v_uint8x32& a, const v_uint8x32& b)' modules/core/include/opencv2/core/hal/intrin_avx.hpp | grep -q '__m256i half = _mm256_sad_epu8(a.val, b.val);'; then
    echo "PASS: intrin_avx.hpp has correct v_reduce_sad for v_uint8x32 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp has incorrect v_reduce_sad for v_uint8x32 (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: intrin_sse.hpp should have correct v_reduce_sad for v_uint8x16 (fixed version has multi-line reduction)
if grep -A 3 'inline unsigned v_reduce_sad(const v_uint8x16& a, const v_uint8x16& b)' modules/core/include/opencv2/core/hal/intrin_sse.hpp | grep -q '__m128i half = _mm_sad_epu8(a.val, b.val);'; then
    echo "PASS: intrin_sse.hpp has correct v_reduce_sad for v_uint8x16 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_sse.hpp has incorrect v_reduce_sad for v_uint8x16 (buggy version)" >&2
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
