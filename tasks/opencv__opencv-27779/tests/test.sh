#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_cuda.cpp" "modules/core/test/test_cuda.cpp"
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/test_cuda.py" "modules/python/test/test_cuda.py"

checks_passed=0
checks_failed=0

# Check 1: CMakeLists.txt should have HAVE_CUDA compile definitions restored
if grep -q 'if (HAVE_CUDA)' modules/core/CMakeLists.txt && \
   grep -q 'ocv_target_compile_definitions(opencv_test_core PRIVATE "HAVE_CUDA=1")' modules/core/CMakeLists.txt && \
   grep -q 'ocv_target_compile_definitions(opencv_perf_core PRIVATE "HAVE_CUDA=1")' modules/core/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt has HAVE_CUDA compile definitions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt missing HAVE_CUDA compile definitions (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: pyopencv_core.hpp should support extended DLPack types (CV_Bool, CV_16BF, CV_64S, CV_32U, CV_64U)
if grep -q 'case CV_Bool: dtype.code = kDLBool; break;' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q 'case CV_16BF: dtype.code = kDLBfloat; break;' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q 'case CV_8S: case CV_16S: case CV_32S: case CV_64S: dtype.code = kDLInt; break;' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q 'case CV_8U: case CV_16U: case CV_32U: case CV_64U: dtype.code = kDLUInt; break;' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp has extended DLPack type support in GetDLPackType (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing extended DLPack type support in GetDLPackType (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: pyopencv_core.hpp should support CV_64SC conversion from DLPack
if grep -q 'case 64: return CV_64SC(channels);' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp supports CV_64SC conversion from DLPack (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing CV_64SC conversion from DLPack (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: pyopencv_core.hpp should support CV_32UC and CV_64UC conversion from DLPack
if grep -q 'case 32: return CV_32UC(channels);' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q 'case 64: return CV_64UC(channels);' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp supports CV_32UC and CV_64UC conversion from DLPack (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing CV_32UC/CV_64UC conversion from DLPack (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: pyopencv_core.hpp should support kDLBool and kDLBfloat conversion
if grep -q 'if (dtype.code == kDLBool)' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q 'return CV_BoolC(channels);' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q 'if (dtype.code == kDLBfloat)' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q 'return CV_16BFC(channels);' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp supports kDLBool and kDLBfloat conversion (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing kDLBool/kDLBfloat conversion (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: pyopencv_core.hpp should have Python method definitions for extended types
if grep -q '{"CV_32UC", (PyCFunction)(pycvMakeTypeCh<CV_32U>), METH_O, "CV_32UC(channels) -> retval"},' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q '{"CV_64UC", (PyCFunction)(pycvMakeTypeCh<CV_64U>), METH_O, "CV_64UC(channels) -> retval"},' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q '{"CV_64SC", (PyCFunction)(pycvMakeTypeCh<CV_64S>), METH_O, "CV_64SC(channels) -> retval"},' modules/core/misc/python/pyopencv_core.hpp && \
   grep -q '{"CV_16BFC", (PyCFunction)(pycvMakeTypeCh<CV_16BF>), METH_O, "CV_16BFC(channels) -> retval"}' modules/core/misc/python/pyopencv_core.hpp; then
    echo "PASS: pyopencv_core.hpp has Python method definitions for extended types (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_core.hpp missing Python method definitions for extended types (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: gpu_mat.cu should use CV_DEPTH_CURR_MAX instead of hard-coded 7
if grep -q 'CV_Assert(sdepth < CV_DEPTH_CURR_MAX && ddepth < CV_DEPTH_CURR_MAX);' modules/core/src/cuda/gpu_mat.cu; then
    echo "PASS: gpu_mat.cu uses CV_DEPTH_CURR_MAX (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gpu_mat.cu uses hard-coded depth limit (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gpu_mat.cu should have extended conversion table with CV_DEPTH_CURR_MAX size
if grep -q 'static const func_t funcs\[CV_DEPTH_CURR_MAX\]\[CV_DEPTH_CURR_MAX\] =' modules/core/src/cuda/gpu_mat.cu; then
    echo "PASS: gpu_mat.cu has extended conversion table (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gpu_mat.cu has limited 7x7 conversion table (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: gpu_mat.cu should have convertToNoScale entries for uint64_t, int64_t, uint32_t
if grep -q 'convertToNoScale<uchar, uint64_t>' modules/core/src/cuda/gpu_mat.cu && \
   grep -q 'convertToNoScale<uchar, int64_t>' modules/core/src/cuda/gpu_mat.cu && \
   grep -q 'convertToNoScale<uchar, uint32_t>' modules/core/src/cuda/gpu_mat.cu; then
    echo "PASS: gpu_mat.cu has convertToNoScale for extended types (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gpu_mat.cu missing convertToNoScale for extended types (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: test_cuda.cpp should have GpuMat convertTo tests
if grep -q 'typedef testing::TestWithParam< tuple<perf::MatType, perf::MatType> > GpuMat;' modules/core/test/test_cuda.cpp && \
   grep -q 'TEST_P(GpuMat, convertTo)' modules/core/test/test_cuda.cpp && \
   grep -q 'TEST_P(GpuMat, convertToScale)' modules/core/test/test_cuda.cpp && \
   grep -q 'INSTANTIATE_TEST_CASE_P' modules/core/test/test_cuda.cpp; then
    echo "PASS: test_cuda.cpp has GpuMat convertTo tests (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_cuda.cpp missing GpuMat convertTo tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: cv2.cpp should publish extended type constants
if grep -q 'PUBLISH(CV_32U);' modules/python/src2/cv2.cpp && \
   grep -q 'PUBLISH(CV_64U);' modules/python/src2/cv2.cpp && \
   grep -q 'PUBLISH(CV_64S);' modules/python/src2/cv2.cpp; then
    echo "PASS: cv2.cpp publishes extended type constants (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cv2.cpp missing extended type constants (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: cv2_numpy.cpp should preserve uint32, int64, uint64 types
if grep -q 'depth == CV_32U ? NPY_UINT32' modules/python/src2/cv2_numpy.cpp && \
   grep -q 'depth == CV_64S ? NPY_INT64' modules/python/src2/cv2_numpy.cpp; then
    echo "PASS: cv2_numpy.cpp preserves uint32/int64/uint64 types (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cv2_numpy.cpp doesn't preserve extended integer types (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_cuda.py should test extended DLPack types
if grep -q 'for dtype in \[np.int8, np.uint8, np.int16, np.uint16, np.float16, np.int32, np.float32, np.float64, np.int64, np.uint32, np.uint64, np.bool_\]:' modules/python/test/test_cuda.py; then
    echo "PASS: test_cuda.py tests extended DLPack types (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_cuda.py doesn't test extended DLPack types (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: test_cuda.py should include type preservation assertion
if grep -q 'self.assertEqual(ref.dtype, test.dtype)' modules/python/test/test_cuda.py; then
    echo "PASS: test_cuda.py includes dtype preservation assertion (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_cuda.py missing dtype preservation assertion (buggy version)" >&2
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
