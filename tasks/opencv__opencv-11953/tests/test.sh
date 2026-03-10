#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin.cpp" "modules/core/test/test_intrin.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin.fp16.cpp" "modules/core/test/test_intrin.fp16.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin_utils.hpp" "modules/core/test/test_intrin_utils.hpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_math.cpp" "modules/core/test/test_math.cpp"

checks_passed=0
checks_failed=0

# PR #11953: Wide universal intrinsics support

# Check 1: V_TypeTraits should be properly defined in intrin.hpp
if grep -q 'template<typename _Tp> struct V_TypeTraits' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null; then
    echo "PASS: intrin.hpp has V_TypeTraits template"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have V_TypeTraits template definition" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Wide vector types should be declared (e.g., v_uint8x32 for 256-bit)
if grep -q 'v_uint8x32\|v_int8x32\|v_uint16x16\|v_int16x16' modules/core/include/opencv2/core/hal/intrin_avx.hpp 2>/dev/null || \
   grep -q 'nlanes = 32' modules/core/include/opencv2/core/hal/intrin_avx.hpp 2>/dev/null; then
    echo "PASS: AVX intrinsics define wide vector types"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: AVX intrinsics should define 256-bit wide vector types" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: FP16 support should be present
if grep -q 'v_float16' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null || \
   grep -q 'float16_t\|__fp16' modules/core/src/convert.fp16.cpp 2>/dev/null; then
    echo "PASS: FP16 support is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FP16 support should be implemented" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Math functions should use SIMD intrinsics (check mathfuncs_core.simd.hpp)
if [ -f modules/core/src/mathfuncs_core.simd.hpp ]; then
    if grep -q 'v_sqrt\|v_invsqrt\|v_magnitude' modules/core/src/mathfuncs_core.simd.hpp 2>/dev/null; then
        echo "PASS: mathfuncs_core.simd.hpp uses vector intrinsics for math"
        checks_passed=$((checks_passed + 1))
    else
        echo "FAIL: mathfuncs_core.simd.hpp should use vector intrinsics" >&2
        checks_failed=$((checks_failed + 1))
    fi
else
    echo "FAIL: mathfuncs_core.simd.hpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: CPU optimization namespace should be defined
if grep -q 'CV_CPU_OPTIMIZATION_HAL_NAMESPACE' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null; then
    echo "PASS: CPU optimization namespace is defined"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CPU optimization namespace should be defined in intrin.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test files should be present and contain intrinsics tests
if [ -f modules/core/test/test_intrin.cpp ]; then
    if grep -q 'TEST\|INSTANTIATE_TEST' modules/core/test/test_intrin.cpp 2>/dev/null; then
        echo "PASS: test_intrin.cpp contains test definitions"
        checks_passed=$((checks_passed + 1))
    else
        echo "FAIL: test_intrin.cpp should contain test definitions" >&2
        checks_failed=$((checks_failed + 1))
    fi
else
    echo "FAIL: test_intrin.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: FP16 test file should be present
if [ -f modules/core/test/test_intrin.fp16.cpp ]; then
    echo "PASS: test_intrin.fp16.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_intrin.fp16.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Math test file should be present
if [ -f modules/core/test/test_math.cpp ]; then
    echo "PASS: test_math.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_math.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: AVX intrinsics should have proper include guards
if grep -q '#ifndef.*AVX\|#ifdef.*AVX' modules/core/include/opencv2/core/hal/intrin_avx.hpp 2>/dev/null; then
    echo "PASS: intrin_avx.hpp has AVX preprocessor guards"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_avx.hpp should have AVX preprocessor guards" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: SSE intrinsics should also be updated for consistency
if [ -f modules/core/include/opencv2/core/hal/intrin_sse.hpp ]; then
    echo "PASS: intrin_sse.hpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin_sse.hpp should exist" >&2
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
