#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/test_features2d.js" "modules/js/test/test_features2d.js"
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/tests.html" "modules/js/test/tests.html"
mkdir -p "modules/js/test"
cp "/tests/modules/js/test/tests.js" "modules/js/test/tests.js"

checks_passed=0
checks_failed=0

# PR #13763 fixes OpenCL kernel argument handling and MVN layer kernel build options
# HEAD (fcec053d59a8e30cbac7db571fcd448bfc98dd53): Fixed version with proper error logging and kernel defines
# BASE (after bug.patch): Buggy version without error logging and kernel defines
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: ocl.cpp should have CV_LOG_ERROR for negative arg_index (fixed version)
if grep -q 'CV_LOG_ERROR(NULL, cv::format("OpenCL: Kernel(%s)::set(arg_index=%d): negative arg_index",' modules/core/src/ocl.cpp; then
    echo "PASS: ocl.cpp has CV_LOG_ERROR for negative arg_index (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocl.cpp does not have CV_LOG_ERROR for negative arg_index (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: ocl.cpp should handle empty UMat with PTR_ONLY flag (fixed version)
if grep -q 'if (ptronly && arg.m->empty())' modules/core/src/ocl.cpp; then
    echo "PASS: ocl.cpp handles empty UMat with PTR_ONLY flag (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocl.cpp does not handle empty UMat with PTR_ONLY flag (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: ocl.cpp should have CV_LOG_ERROR when cl_mem handle creation fails (fixed version)
if grep -q 'CV_LOG_ERROR(NULL, cv::format("OpenCL: Kernel(%s)::set(arg_index=%d, flags=%d): can'"'"'t create cl_mem handle for passed UMat buffer (addr=%p)",' modules/core/src/ocl.cpp; then
    echo "PASS: ocl.cpp has CV_LOG_ERROR for cl_mem handle creation failure (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocl.cpp does not have CV_LOG_ERROR for cl_mem handle creation failure (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: mvn_layer.cpp should define LOCAL_SIZE constant (fixed version)
if grep -q 'const unsigned LOCAL_SIZE = 128;' modules/dnn/src/layers/mvn_layer.cpp; then
    echo "PASS: mvn_layer.cpp defines LOCAL_SIZE constant (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp does not define LOCAL_SIZE constant (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: mvn_layer.cpp should include LOCAL_SIZE in build options (fixed version)
if grep -q 'String opts = format(" -DT=%s -DT4=%s -Dconvert_T=%s -DLOCAL_SIZE=%u"' modules/dnn/src/layers/mvn_layer.cpp; then
    echo "PASS: mvn_layer.cpp includes LOCAL_SIZE in build options (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp does not include LOCAL_SIZE in build options (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: mvn_layer.cpp should use LOCAL_SIZE variable for localsize array (fixed version)
if grep -q 'size_t localsize\[\] = { LOCAL_SIZE };' modules/dnn/src/layers/mvn_layer.cpp; then
    echo "PASS: mvn_layer.cpp uses LOCAL_SIZE variable for localsize array (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp does not use LOCAL_SIZE variable (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: mvn_layer.cpp should add KERNEL_MEAN_FUSE define to mean_fuse4 kernel (fixed version)
if grep -q 'ocl::Kernel k("mean_fuse4", ocl::dnn::mvn_oclsrc, buildopt + " -DKERNEL_MEAN_FUSE");' modules/dnn/src/layers/mvn_layer.cpp; then
    echo "PASS: mvn_layer.cpp adds KERNEL_MEAN_FUSE define (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp does not add KERNEL_MEAN_FUSE define (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: mvn_layer.cpp should add KERNEL_MVN_FUSE define to mvn_fuse4 kernel (fixed version)
if grep -q 'ocl::Kernel k1("mvn_fuse4", ocl::dnn::mvn_oclsrc, buildopt + " -DKERNEL_MVN_FUSE");' modules/dnn/src/layers/mvn_layer.cpp; then
    echo "PASS: mvn_layer.cpp adds KERNEL_MVN_FUSE define (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp does not add KERNEL_MVN_FUSE define (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: mvn_layer.cpp should add KERNEL_MEAN define to calc_mean kernel (fixed version)
if grep -q 'ocl::Kernel kernel(kname.c_str(), ocl::dnn::mvn_oclsrc, buildopt + " -DKERNEL_MEAN");' modules/dnn/src/layers/mvn_layer.cpp; then
    echo "PASS: mvn_layer.cpp adds KERNEL_MEAN define (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp does not add KERNEL_MEAN define (buggy version)" >&2
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
