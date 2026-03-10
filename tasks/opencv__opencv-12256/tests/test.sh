#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin_utils.hpp" "modules/core/test/test_intrin_utils.hpp"

checks_passed=0
checks_failed=0

# PR #12256: Separate FP16 SIMD capabilities from baseline FP16 support
# The fix introduces CV_SIMD_FP16 and CV_SIMD128_FP16/CV_SIMD256_FP16 macros
# to distinguish between native FP16 SIMD vector support and baseline FP16 conversion support.
# For harbor testing:
# - HEAD (67d46dfc6ce938b40cdd731d0af6b4f6b7bf14ab): Fixed version with CV_SIMD_FP16 separation
# - BASE (after bug.patch): Buggy version without proper separation
# - FIXED (after oracle applies fix): Back to fixed version

# Check 1: intrin.hpp should have CV_SIMD128_FP16 macro definition (fixed version)
if grep -q '#ifndef CV_SIMD128_FP16' modules/core/include/opencv2/core/hal/intrin.hpp && \
   grep -q '#define CV_SIMD128_FP16 0' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp has CV_SIMD128_FP16 macro - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have CV_SIMD128_FP16 macro - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: intrin.hpp should have CV_SIMD256_FP16 macro definition (fixed version)
if grep -q '#ifndef CV_SIMD256_FP16' modules/core/include/opencv2/core/hal/intrin.hpp && \
   grep -q '#define CV_SIMD256_FP16 0' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp has CV_SIMD256_FP16 macro - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have CV_SIMD256_FP16 macro - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: intrin.hpp should have CV_SIMD_FP16 macro definition (fixed version)
if grep -q '#ifndef CV_SIMD_FP16' modules/core/include/opencv2/core/hal/intrin.hpp && \
   grep -q '#define CV_SIMD_FP16 0' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp has CV_SIMD_FP16 macro - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have CV_SIMD_FP16 macro - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: intrin.hpp should use CV_SIMD128_FP16 for v_float16x8 traits (fixed version)
if grep -q '#if CV_SIMD128_FP16' modules/core/include/opencv2/core/hal/intrin.hpp && \
   grep -A1 '#if CV_SIMD128_FP16' modules/core/include/opencv2/core/hal/intrin.hpp | grep -q 'CV_DEF_REG_TRAITS(v, v_float16x8'; then
    echo "PASS: intrin.hpp uses CV_SIMD128_FP16 for v_float16x8 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should use CV_SIMD128_FP16 for v_float16x8 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: intrin.hpp should define CV_SIMD_FP16 from CV_SIMD256_FP16 in 256-bit namespace (fixed version)
if grep -q '#define CV_SIMD_FP16 CV_SIMD256_FP16' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp defines CV_SIMD_FP16 from CV_SIMD256_FP16 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should define CV_SIMD_FP16 from CV_SIMD256_FP16 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: intrin.hpp should define CV_SIMD_FP16 from CV_SIMD128_FP16 in 128-bit namespace (fixed version)
if grep -q '#define CV_SIMD_FP16 CV_SIMD128_FP16' modules/core/include/opencv2/core/hal/intrin.hpp; then
    echo "PASS: intrin.hpp defines CV_SIMD_FP16 from CV_SIMD128_FP16 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should define CV_SIMD_FP16 from CV_SIMD128_FP16 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: intrin_neon.hpp should have CV_SIMD128_FP16 conditional definition (fixed version)
if grep -q '# if CV_FP16 && (defined(__GNUC__) && __GNUC__ >= 5)' modules/core/include/opencv2/core/hal/intrin_neon.hpp && \
   grep -A1 '# if CV_FP16 && (defined(__GNUC__) && __GNUC__ >= 5)' modules/core/include/opencv2/core/hal/intrin_neon.hpp | grep -q '#   define CV_SIMD128_FP16 1'; then
    echo "PASS: intrin_neon.hpp has CV_SIMD128_FP16 conditional - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_neon.hpp should have CV_SIMD128_FP16 conditional - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: intrin_neon.hpp should use CV_SIMD128_FP16 for v_float16x8 structure (fixed version)
if grep -B25 'struct v_float16x8' modules/core/include/opencv2/core/hal/intrin_neon.hpp | grep -q '#if CV_SIMD128_FP16'; then
    echo "PASS: intrin_neon.hpp uses CV_SIMD128_FP16 for v_float16x8 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_neon.hpp should use CV_SIMD128_FP16 for v_float16x8 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: intrin_neon.hpp should have separate v128_load_fp16_f32 and v_store_fp16 functions under CV_FP16 (fixed version)
if grep -q 'inline v_float32x4 v128_load_fp16_f32(const short\* ptr)' modules/core/include/opencv2/core/hal/intrin_neon.hpp && \
   grep -q 'inline void v_store_fp16(short\* ptr, const v_float32x4& a)' modules/core/include/opencv2/core/hal/intrin_neon.hpp; then
    echo "PASS: intrin_neon.hpp has v128_load_fp16_f32 and v_store_fp16 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_neon.hpp should have v128_load_fp16_f32 and v_store_fp16 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: intrin_avx.hpp should have CV_SIMD256_FP16 set to 0 (fixed version)
if grep -q '#define CV_SIMD256_FP16 0' modules/core/include/opencv2/core/hal/intrin_avx.hpp; then
    echo "PASS: intrin_avx.hpp has CV_SIMD256_FP16 = 0 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp should have CV_SIMD256_FP16 = 0 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: intrin_avx.hpp should have v256_load_fp16_f32 and v_store_fp16 (fixed version)
if grep -q 'inline v_float32x8 v256_load_fp16_f32(const short\* ptr)' modules/core/include/opencv2/core/hal/intrin_avx.hpp && \
   grep -q 'inline void v_store_fp16(short\* ptr, const v_float32x8& a)' modules/core/include/opencv2/core/hal/intrin_avx.hpp; then
    echo "PASS: intrin_avx.hpp has v256_load_fp16_f32 and v_store_fp16 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp should have v256_load_fp16_f32 and v_store_fp16 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: intrin_sse.hpp should have CV_SIMD128_FP16 set to 0 (fixed version)
if grep -q '#define CV_SIMD128_FP16 0' modules/core/include/opencv2/core/hal/intrin_sse.hpp; then
    echo "PASS: intrin_sse.hpp has CV_SIMD128_FP16 = 0 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_sse.hpp should have CV_SIMD128_FP16 = 0 - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: intrin_sse.hpp should have v128_load_fp16_f32 and v_store_fp16 (fixed version)
if grep -q 'inline v_float32x4 v128_load_fp16_f32(const short\* ptr)' modules/core/include/opencv2/core/hal/intrin_sse.hpp && \
   grep -q 'inline void v_store_fp16(short\* ptr, const v_float32x4& a)' modules/core/include/opencv2/core/hal/intrin_sse.hpp; then
    echo "PASS: intrin_sse.hpp has v128_load_fp16_f32 and v_store_fp16 - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_sse.hpp should have v128_load_fp16_f32 and v_store_fp16 - buggy version" >&2
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
