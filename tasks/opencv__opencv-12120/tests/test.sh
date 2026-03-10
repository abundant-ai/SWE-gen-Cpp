#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin.cpp" "modules/core/test/test_intrin.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin128.simd.hpp" "modules/core/test/test_intrin128.simd.hpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin256.simd.hpp" "modules/core/test/test_intrin256.simd.hpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_intrin_utils.hpp" "modules/core/test/test_intrin_utils.hpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_precomp.hpp" "modules/core/test/test_precomp.hpp"

checks_passed=0
checks_failed=0

# PR #12120: Support for dispatched SIMD test files and 256-bit vector intrinsic fixes

# Check 1: OpenCVCompilerOptimizations.cmake should have __ocv_add_dispatched_file helper macro
if grep -q "^macro(__ocv_add_dispatched_file filename target_src_var src_directory dst_directory precomp_hpp optimizations_var)" cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: OpenCVCompilerOptimizations.cmake has __ocv_add_dispatched_file helper macro"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCVCompilerOptimizations.cmake should have __ocv_add_dispatched_file helper macro" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: __ocv_add_dispatched_file should use parameterized src_directory and precomp_hpp
if grep -q '#include.*\${src_directory}/\${precomp_hpp}' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: __ocv_add_dispatched_file uses parameterized src_directory and precomp_hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: __ocv_add_dispatched_file should use parameterized src_directory and precomp_hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: __ocv_add_dispatched_file should use dst_directory parameter for output files
if grep -q 'set(__file "${CMAKE_CURRENT_BINARY_DIR}/${dst_directory}${filename}.${OPT_LOWER}.cpp")' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: __ocv_add_dispatched_file uses dst_directory parameter for output files"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: __ocv_add_dispatched_file should use dst_directory parameter for output files" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: __ocv_add_dispatched_file should append to parameterized target_src_var
if grep -q 'list(APPEND ${target_src_var} "${__file}")' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: __ocv_add_dispatched_file appends to parameterized target_src_var"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: __ocv_add_dispatched_file should append to parameterized target_src_var" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: __ocv_add_dispatched_file should have #undef CV_CPU_SIMD_FILENAME
if grep -q '#undef CV_CPU_SIMD_FILENAME' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: __ocv_add_dispatched_file has #undef CV_CPU_SIMD_FILENAME"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: __ocv_add_dispatched_file should have #undef CV_CPU_SIMD_FILENAME" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: ocv_add_dispatched_file macro should check for TEST mode
if grep -q 'if(" ${ARGV1}" STREQUAL " TEST")' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: ocv_add_dispatched_file checks for TEST mode"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocv_add_dispatched_file should check for TEST mode" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: ocv_add_dispatched_file should call __ocv_add_dispatched_file for TEST mode with test/ directory
if grep -q '__ocv_add_dispatched_file("${filename}" "OPENCV_MODULE_${the_module}_TEST_SOURCES_DISPATCHED" "${CMAKE_CURRENT_LIST_DIR}/test" "test/" "test_precomp.hpp" __optimizations)' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: ocv_add_dispatched_file calls __ocv_add_dispatched_file for TEST mode with test/ directory"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocv_add_dispatched_file should call __ocv_add_dispatched_file for TEST mode with test/ directory" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: ocv_add_dispatched_file should call __ocv_add_dispatched_file for non-TEST mode with src/ directory
if grep -q '__ocv_add_dispatched_file("${filename}" "OPENCV_MODULE_${the_module}_SOURCES_DISPATCHED" "${CMAKE_CURRENT_LIST_DIR}/src" "" "precomp.hpp" __optimizations)' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: ocv_add_dispatched_file calls __ocv_add_dispatched_file for non-TEST mode with src/ directory"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocv_add_dispatched_file should call __ocv_add_dispatched_file for non-TEST mode with src/ directory" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: OpenCVModule.cmake should append TEST_SOURCES_DISPATCHED to test sources
if grep -q 'if(OPENCV_MODULE_${the_module}_TEST_SOURCES_DISPATCHED)' cmake/OpenCVModule.cmake 2>/dev/null && \
   grep -q 'list(APPEND OPENCV_TEST_${the_module}_SOURCES ${OPENCV_MODULE_${the_module}_TEST_SOURCES_DISPATCHED})' cmake/OpenCVModule.cmake 2>/dev/null; then
    echo "PASS: OpenCVModule.cmake appends TEST_SOURCES_DISPATCHED to test sources"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCVModule.cmake should append TEST_SOURCES_DISPATCHED to test sources" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: OpenCVModule.cmake should add test directory to include directories
if grep -q 'if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/test")' cmake/OpenCVModule.cmake 2>/dev/null && \
   grep -q 'ocv_target_include_directories(${the_target} "${CMAKE_CURRENT_BINARY_DIR}/test")' cmake/OpenCVModule.cmake 2>/dev/null; then
    echo "PASS: OpenCVModule.cmake adds test directory to include directories"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCVModule.cmake should add test directory to include directories" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: modules/core/CMakeLists.txt should have dispatched test_intrin128 with TEST keyword
if grep -q 'ocv_add_dispatched_file_force_all(test_intrin128 TEST SSE2 SSE3 SSSE3 SSE4_1 SSE4_2 AVX FP16 AVX2)' modules/core/CMakeLists.txt 2>/dev/null; then
    echo "PASS: modules/core/CMakeLists.txt has dispatched test_intrin128 with TEST keyword"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/core/CMakeLists.txt should have dispatched test_intrin128 with TEST keyword" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: modules/core/CMakeLists.txt should have dispatched test_intrin256 with TEST keyword
if grep -q 'ocv_add_dispatched_file_force_all(test_intrin256 TEST AVX2)' modules/core/CMakeLists.txt 2>/dev/null; then
    echo "PASS: modules/core/CMakeLists.txt has dispatched test_intrin256 with TEST keyword"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/core/CMakeLists.txt should have dispatched test_intrin256 with TEST keyword" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: intrin.hpp should NOT have early CV_SIMD definition (moved to after width selection)
if ! sed -n '204,220p' modules/core/include/opencv2/core/hal/intrin.hpp | grep -q '#define CV_SIMD 1' 2>/dev/null; then
    echo "PASS: intrin.hpp does not have early CV_SIMD definition in lines 204-220"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should not have early CV_SIMD definition in lines 204-220 (moved later)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: intrin.hpp should have CV__SIMD_FORCE_WIDTH check for SIMD512
if grep -q '#if CV_SIMD512 && (!defined(CV__SIMD_FORCE_WIDTH) || CV__SIMD_FORCE_WIDTH == 512)' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null; then
    echo "PASS: intrin.hpp has CV__SIMD_FORCE_WIDTH check for SIMD512"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have CV__SIMD_FORCE_WIDTH check for SIMD512" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: intrin.hpp should have CV__SIMD_FORCE_WIDTH check for SIMD256
if grep -q '#elif CV_SIMD256 && (!defined(CV__SIMD_FORCE_WIDTH) || CV__SIMD_FORCE_WIDTH == 256)' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null; then
    echo "PASS: intrin.hpp has CV__SIMD_FORCE_WIDTH check for SIMD256"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have CV__SIMD_FORCE_WIDTH check for SIMD256" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: intrin.hpp should have CV__SIMD_FORCE_WIDTH check for SIMD128
if grep -q '#elif (CV_SIMD128 || CV_SIMD128_CPP) && (!defined(CV__SIMD_FORCE_WIDTH) || CV__SIMD_FORCE_WIDTH == 128)' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null; then
    echo "PASS: intrin.hpp has CV__SIMD_FORCE_WIDTH check for SIMD128"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have CV__SIMD_FORCE_WIDTH check for SIMD128" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: intrin.hpp should define CV_SIMD within SIMD128 branch
if grep -A 3 '#elif (CV_SIMD128 || CV_SIMD128_CPP) && (!defined(CV__SIMD_FORCE_WIDTH) || CV__SIMD_FORCE_WIDTH == 128)' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null | grep -q '#define CV_SIMD CV_SIMD128' 2>/dev/null; then
    echo "PASS: intrin.hpp defines CV_SIMD within SIMD128 branch"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should define CV_SIMD within SIMD128 branch" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: intrin.hpp should have fallback #ifndef CV_SIMD at the end
if grep -q '#ifndef CV_SIMD' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null && \
   grep -A 1 '#ifndef CV_SIMD' modules/core/include/opencv2/core/hal/intrin.hpp 2>/dev/null | grep -q '#define CV_SIMD 0' 2>/dev/null; then
    echo "PASS: intrin.hpp has fallback #ifndef CV_SIMD at the end"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: intrin.hpp should have fallback #ifndef CV_SIMD at the end" >&2
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
