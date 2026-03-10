#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_mat.cpp" "modules/core/test/test_mat.cpp"
mkdir -p "modules/cudafeatures2d/test"
cp "/tests/modules/cudafeatures2d/test/test_features2d.cpp" "modules/cudafeatures2d/test/test_features2d.cpp"

checks_passed=0
checks_failed=0

# PR #12377: Remove rawIn/rawOut/rawInOut API support
# For harbor testing:
# - HEAD (00cbb894ec1ca44bf869ea79521cb815235e6a2e): Fixed version with rawIn/rawOut/rawInOut API
# - BASE (after bug.patch): Buggy version with API removed
# - FIXED (after oracle applies fix): Back to fixed version with API restored
#
# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: mat.hpp should have rawIn/rawOut/rawInOut helper function declarations (fixed version)
if grep -q 'template<typename _Tp> static inline _InputArray rawIn(_Tp& v);' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'template<typename _Tp> static inline _OutputArray rawOut(_Tp& v);' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'template<typename _Tp> static inline _InputOutputArray rawInOut(_Tp& v);' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has rawIn/rawOut/rawInOut helper declarations - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing rawIn/rawOut/rawInOut helpers - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: mat.hpp should have documentation for custom types (fixed version)
if grep -q 'In general, type support is limited to cv::Mat types. Other types are forbidden.' modules/core/include/opencv2/core/mat.hpp && \
   grep -q 'To pass such custom type use rawIn() / rawOut() / rawInOut() wrappers.' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has custom types documentation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing custom types documentation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: mat.hpp should have _InputArray::rawIn static method declaration (fixed version)
if grep -q 'template<typename _Tp> static _InputArray rawIn(const std::vector<_Tp>& vec);' modules/core/include/opencv2/core/mat.hpp; then
    echo "PASS: mat.hpp has _InputArray::rawIn declaration - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp missing _InputArray::rawIn declaration - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: mat.inl.hpp should have rawType() function (fixed version)
if grep -q 'template<typename _Tp> static inline' modules/core/include/opencv2/core/mat.inl.hpp && \
   grep -q 'int rawType()' modules/core/include/opencv2/core/mat.inl.hpp && \
   grep -q 'CV_StaticAssert(sizeof(_Tp) <= CV_CN_MAX' modules/core/include/opencv2/core/mat.inl.hpp; then
    echo "PASS: mat.inl.hpp has rawType() function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.inl.hpp missing rawType() function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: mat.inl.hpp should have _InputArray::rawIn implementation (fixed version)
if grep -q '_InputArray _InputArray::rawIn(const std::vector<_Tp>& vec)' modules/core/include/opencv2/core/mat.inl.hpp && \
   grep -q 'v.flags = _InputArray::FIXED_TYPE + _InputArray::STD_VECTOR + rawType<_Tp>() + ACCESS_READ;' modules/core/include/opencv2/core/mat.inl.hpp; then
    echo "PASS: mat.inl.hpp has _InputArray::rawIn implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.inl.hpp missing _InputArray::rawIn implementation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: mat.inl.hpp should have global helper wrapper implementations (fixed version)
if grep -q 'template<typename _Tp> static inline _InputArray rawIn(_Tp& v) { return _InputArray::rawIn(v); }' modules/core/include/opencv2/core/mat.inl.hpp && \
   grep -q 'template<typename _Tp> static inline _OutputArray rawOut(_Tp& v) { return _OutputArray::rawOut(v); }' modules/core/include/opencv2/core/mat.inl.hpp && \
   grep -q 'template<typename _Tp> static inline _InputOutputArray rawInOut(_Tp& v) { return _InputOutputArray::rawInOut(v); }' modules/core/include/opencv2/core/mat.inl.hpp; then
    echo "PASS: mat.inl.hpp has global helper wrapper implementations - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.inl.hpp missing global helper wrappers - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: matrix_wrap.cpp should have Vec<int, 5> case (fixed version)
if grep -q 'case 20:' modules/core/src/matrix_wrap.cpp && \
   grep -q 'Vec<int, 5>' modules/core/src/matrix_wrap.cpp; then
    echo "PASS: matrix_wrap.cpp has Vec<int, 5> case - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: matrix_wrap.cpp missing Vec<int, 5> case - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: CMakeLists.txt should NOT have OPENCV_TRAITS_ENABLE_DEPRECATED (fixed version removes it)
if ! grep -q 'OPENCV_TRAITS_ENABLE_DEPRECATED' modules/core/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt has no OPENCV_TRAITS_ENABLE_DEPRECATED - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt has OPENCV_TRAITS_ENABLE_DEPRECATED - buggy version" >&2
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
