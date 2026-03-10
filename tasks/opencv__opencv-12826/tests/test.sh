#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_arithm.cpp" "modules/core/test/test_arithm.cpp"
mkdir -p "modules/gapi/test/common"
cp "/tests/modules/gapi/test/common/gapi_core_tests_inl.hpp" "modules/gapi/test/common/gapi_core_tests_inl.hpp"

checks_passed=0
checks_failed=0

# PR #12826: Fix division by zero handling in ARM NEON-optimized division functions
# For harbor testing:
# - HEAD (d5d059690f7b576b5f30b4954b34949a71605b17): Fixed version WITH static_assert and div-by-zero checks
# - BASE (after bug.patch): Buggy version WITHOUT static_assert and div-by-zero checks
# - FIXED (after fix.patch): Back to fixed version WITH static_assert and div-by-zero checks

# Check 1: div() function SHOULD have static_assert for integer types
if grep -q 'static_assert(std::numeric_limits<T>::is_integer, "template implementation is for integer types only");' 3rdparty/carotene/src/div.cpp; then
    echo "PASS: div.cpp has static_assert in div() function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: div.cpp missing static_assert in div() function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: recip() function SHOULD have static_assert for integer types
if grep -q 'static_assert(std::numeric_limits<T>::is_integer, "template implementation is for integer types only");' 3rdparty/carotene/src/div.cpp; then
    echo "PASS: div.cpp has static_assert in recip() function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: div.cpp missing static_assert in recip() function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: div(f32) SHOULD NOT have v_zero variable (buggy version has it)
if grep -q 'float32x4_t v_zero = vdupq_n_f32(0.0f);' 3rdparty/carotene/src/div.cpp; then
    echo "FAIL: div.cpp has v_zero variable in div(f32) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: div.cpp does not have v_zero variable in div(f32) - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: div(f32) SHOULD NOT use vceqq_f32 masking (buggy version has it)
if grep -q 'uint32x4_t v_mask = vceqq_f32(v_src1,v_zero);' 3rdparty/carotene/src/div.cpp; then
    echo "FAIL: div.cpp uses vceqq_f32 masking - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: div.cpp does not use vceqq_f32 masking - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: div(f32) SHOULD NOT use vbicq_u32 masking (buggy version has it)
if grep -q 'vbicq_u32' 3rdparty/carotene/src/div.cpp; then
    echo "FAIL: div.cpp uses vbicq_u32 masking - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: div.cpp does not use vbicq_u32 masking - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 6: div(f32) scalar fallback SHOULD NOT have ternary check (buggy version has it)
if grep -q 'dst\[j\] = src1\[j\] ? src0\[j\] / src1\[j\] : 0.0f;' 3rdparty/carotene/src/div.cpp; then
    echo "FAIL: div.cpp has ternary div-by-zero check in scalar fallback - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: div.cpp does not have ternary div-by-zero check in scalar fallback - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 7: div(f32, scale) scalar fallback SHOULD NOT have ternary check (buggy version has it)
if grep -q 'dst\[j\] = src1\[j\] ? src0\[j\] \* scale / src1\[j\] : 0.0f;' 3rdparty/carotene/src/div.cpp; then
    echo "FAIL: div.cpp has ternary div-by-zero check in scaled scalar fallback - buggy version" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: div.cpp does not have ternary div-by-zero check in scaled scalar fallback - fixed version"
    checks_passed=$((checks_passed + 1))
fi

# Check 8: Verify proper NEON intrinsics usage (fixed version should use vmulq_f32 directly)
if grep -q 'vst1q_f32(dst + j, vmulq_f32(v_src0, internal::vrecpq_f32(v_src1)));' 3rdparty/carotene/src/div.cpp; then
    echo "PASS: div.cpp uses direct vmulq_f32 without masking - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: div.cpp does not use direct vmulq_f32 - buggy version" >&2
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
