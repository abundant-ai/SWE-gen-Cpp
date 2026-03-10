#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/cudev/test"
cp "/tests/modules/cudev/test/test_scan.cu" "modules/cudev/test/test_scan.cu"

checks_passed=0
checks_failed=0

# PR #13658 refactors CUDA 9+ shuffle and scan implementations
# HEAD (970293a229ef314603ffaf77fc62495bf849aba8): Fixed version with refactored code
# BASE (after bug.patch): Buggy version with old implementations
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: test_scan.cu should exist (it's deleted in BASE, restored in FIXED)
if [ -f "modules/cudev/test/test_scan.cu" ]; then
    echo "PASS: test_scan.cu exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_scan.cu does not exist (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: block/scan.hpp should have CUDA 9+ version
if grep -q '#if __CUDACC_VER_MAJOR__ >= 9' modules/cudev/include/opencv2/cudev/block/scan.hpp && \
   grep -q 'warpScanInclusive(0xFFFFFFFFU, data)' modules/cudev/include/opencv2/cudev/block/scan.hpp; then
    echo "PASS: block/scan.hpp has CUDA 9+ implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: block/scan.hpp missing CUDA 9+ implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: warp/scan.hpp should have CUDA 9+ warpScanInclusive with mask parameter
if grep -q '__device__ T warpScanInclusive(uint mask, T data)' modules/cudev/include/opencv2/cudev/warp/scan.hpp && \
   grep -q '#if __CUDACC_VER_MAJOR__ >= 9' modules/cudev/include/opencv2/cudev/warp/scan.hpp; then
    echo "PASS: warp/scan.hpp has CUDA 9+ warpScanInclusive (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: warp/scan.hpp missing CUDA 9+ warpScanInclusive (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: warp/shuffle.hpp should have compatible_shfl_up function
if grep -q 'template <typename T>' modules/cudev/include/opencv2/cudev/warp/shuffle.hpp && \
   grep -q '__device__ __forceinline__ T compatible_shfl_up(T val, uint delta, int width = warpSize)' modules/cudev/include/opencv2/cudev/warp/shuffle.hpp; then
    echo "PASS: warp/shuffle.hpp has compatible_shfl_up (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: warp/shuffle.hpp missing compatible_shfl_up (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: warp/shuffle.hpp should have shfl_up_sync for CUDA 9+
if grep -q '__device__ __forceinline__ T shfl_up_sync(uint mask, T val, uint delta, int width = warpSize)' modules/cudev/include/opencv2/cudev/warp/shuffle.hpp; then
    echo "PASS: warp/shuffle.hpp has shfl_up_sync (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: warp/shuffle.hpp missing shfl_up_sync (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: grid/detail/integral.hpp should use compatible_shfl_up
if grep -q 'const int n = compatible_shfl_up(sum, i, 32);' modules/cudev/include/opencv2/cudev/grid/detail/integral.hpp; then
    echo "PASS: grid/detail/integral.hpp uses compatible_shfl_up (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grid/detail/integral.hpp does not use compatible_shfl_up (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: cudaimgproc clahe.cu should use cudev instead of cuda::device
if grep -q '#include "opencv2/cudev.hpp"' modules/cudaimgproc/src/cuda/clahe.cu && \
   grep -q 'using namespace cv::cudev;' modules/cudaimgproc/src/cuda/clahe.cu; then
    echo "PASS: clahe.cu uses cudev namespace (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clahe.cu does not use cudev namespace (buggy version)" >&2
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
