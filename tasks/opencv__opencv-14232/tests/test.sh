#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# The fix changes v_popcount return type and v_reduce_sum implementations across SIMD backends.
# We validate by checking header files and test code for the fixed state.

# Check 1: intrin_cpp.hpp should have v_popcount return lane-wise results (fixed version)
if grep -q 'v_reg<typename V_TypeTraits<_Tp>::abs_type, n> v_popcount(const v_reg<_Tp, n>& a)' modules/core/include/opencv2/core/hal/intrin_cpp.hpp; then
    echo "PASS: intrin_cpp.hpp has v_popcount returning lane-wise results (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_cpp.hpp missing lane-wise v_popcount (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: intrin_sse.hpp should have v_popcount returning per-lane results (fixed version)
if grep -q 'inline v_uint8x16 v_popcount(const v_uint8x16& a)' modules/core/include/opencv2/core/hal/intrin_sse.hpp; then
    echo "PASS: intrin_sse.hpp has v_popcount returning v_uint8x16 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_sse.hpp missing v_uint8x16 v_popcount (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: intrin_avx.hpp should have v_popcount returning per-lane results (fixed version)
if grep -q 'inline v_uint8x32 v_popcount(const v_uint8x32& a)' modules/core/include/opencv2/core/hal/intrin_avx.hpp; then
    echo "PASS: intrin_avx.hpp has v_popcount returning v_uint8x32 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp missing v_uint8x32 v_popcount (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: intrin_neon.hpp should have v_popcount returning per-lane results (fixed version)
if grep -q 'inline v_uint8x16 v_popcount(const v_uint8x16& a)' modules/core/include/opencv2/core/hal/intrin_neon.hpp; then
    echo "PASS: intrin_neon.hpp has v_popcount returning v_uint8x16 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_neon.hpp missing v_uint8x16 v_popcount (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: intrin_sse.hpp should have v_reduce_sum for uint16/int16 using expand (fixed version)
if grep -q 'inline int v_reduce_sum(const v_int16x8& a)' modules/core/include/opencv2/core/hal/intrin_sse.hpp && \
   grep -q '{ return v_reduce_sum(v_expand_low(a) + v_expand_high(a)); }' modules/core/include/opencv2/core/hal/intrin_sse.hpp; then
    echo "PASS: intrin_sse.hpp has v_reduce_sum using expand for int16x8 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_sse.hpp missing expand-based v_reduce_sum for int16x8 (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: intrin_avx.hpp should have v_reduce_sum for uint16/int16 using expand (fixed version)
if grep -q 'inline int v_reduce_sum(const v_int16x16& a)' modules/core/include/opencv2/core/hal/intrin_avx.hpp && \
   grep -q '{ return v_reduce_sum(v_expand_low(a) + v_expand_high(a)); }' modules/core/include/opencv2/core/hal/intrin_avx.hpp; then
    echo "PASS: intrin_avx.hpp has v_reduce_sum using expand for int16x16 (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp missing expand-based v_reduce_sum for int16x16 (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_intrin_utils.hpp should use v_reduce_sum(v_popcount(a)) pattern (fixed version)
if grep -q 'unsigned resB = (unsigned)v_reduce_sum(v_popcount(a));' modules/core/test/test_intrin_utils.hpp; then
    echo "PASS: test_intrin_utils.hpp uses v_reduce_sum(v_popcount(a)) pattern (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_intrin_utils.hpp missing v_reduce_sum(v_popcount(a)) pattern (buggy version)" >&2
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
