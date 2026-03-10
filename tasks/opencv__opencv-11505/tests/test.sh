#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/core/misc/java/test"
cp "/tests/modules/core/misc/java/test/MatTest.java" "modules/core/misc/java/test/MatTest.java"
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_thresh.cpp" "modules/imgproc/test/test_thresh.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11505: Handle huge matrices correctly by adding updateContinuityFlag declarations

# Check 1: mat.hpp should have updateContinuityFlag declarations (2 instances for Mat and UMat)
updateContinuityFlag_count=$(grep -c "void updateContinuityFlag()" modules/core/include/opencv2/core/mat.hpp)
if [ "$updateContinuityFlag_count" -eq 2 ]; then
    echo "PASS: mat.hpp has 2 updateContinuityFlag declarations"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.hpp should have 2 updateContinuityFlag declarations, found $updateContinuityFlag_count" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: cuda.hpp should have updateContinuityFlag declaration for GpuMat
if grep -q "void updateContinuityFlag()" modules/core/include/opencv2/core/cuda.hpp; then
    echo "PASS: cuda.hpp has updateContinuityFlag declaration"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cuda.hpp should have updateContinuityFlag declaration" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: mat.inl.hpp should call updateContinuityFlag() (not inline)
if grep -q "updateContinuityFlag()" modules/core/include/opencv2/core/mat.inl.hpp; then
    echo "PASS: mat.inl.hpp calls updateContinuityFlag()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mat.inl.hpp should call updateContinuityFlag()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: matrix.cpp should have updateContinuityFlag function that returns int
if grep -q "int updateContinuityFlag(int flags" modules/core/src/matrix.cpp; then
    echo "PASS: matrix.cpp has global updateContinuityFlag function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: matrix.cpp should have global updateContinuityFlag function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: precomp.hpp should declare global updateContinuityFlag
if grep -q "int updateContinuityFlag(int flags" modules/core/src/precomp.hpp; then
    echo "PASS: precomp.hpp declares global updateContinuityFlag"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: precomp.hpp should declare global updateContinuityFlag" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: matrix.cpp should have Mat::updateContinuityFlag() method
if grep -q "void Mat::updateContinuityFlag()" modules/core/src/matrix.cpp; then
    echo "PASS: matrix.cpp has Mat::updateContinuityFlag() method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: matrix.cpp should have Mat::updateContinuityFlag() method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: umatrix.cpp should have UMat::updateContinuityFlag() method
if grep -q "void UMat::updateContinuityFlag()" modules/core/src/umatrix.cpp; then
    echo "PASS: umatrix.cpp has UMat::updateContinuityFlag() method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: umatrix.cpp should have UMat::updateContinuityFlag() method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: cuda_gpu_mat.cpp should have GpuMat::updateContinuityFlag() method
if grep -q "void cv::cuda::GpuMat::updateContinuityFlag()" modules/core/src/cuda_gpu_mat.cpp; then
    echo "PASS: cuda_gpu_mat.cpp has GpuMat::updateContinuityFlag() method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cuda_gpu_mat.cpp should have GpuMat::updateContinuityFlag() method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: imgproc/test/test_thresh.cpp should have the huge matrix test
if grep -q "TEST.*Imgproc_Threshold.*huge" modules/imgproc/test/test_thresh.cpp; then
    echo "PASS: test_thresh.cpp has huge matrix test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_thresh.cpp should have huge matrix test" >&2
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
