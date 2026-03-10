#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/cudaoptflow/test"
cp "/tests/modules/cudaoptflow/test/test_optflow.cpp" "modules/cudaoptflow/test/test_optflow.cpp"

checks_passed=0
checks_failed=0

# PR #13625 fixes Farneback optical flow OPTFLOW_USE_INITIAL_FLOW handling
# HEAD (4366c8734fa7cf69c4a9bdcea91f41d1af345e9c): Fixed version with proper flag handling
# BASE (after bug.patch): Buggy version with simplified flow initialization
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: farneback.cpp should have OPTFLOW_USE_INITIAL_FLOW flag handling in calc()
if grep -q 'if (flags_ & OPTFLOW_USE_INITIAL_FLOW)' modules/cudaoptflow/src/farneback.cpp && \
   grep -q 'GpuMat flow = _flow.getGpuMat();' modules/cudaoptflow/src/farneback.cpp && \
   grep -q 'cuda::split(flow, _flows, stream);' modules/cudaoptflow/src/farneback.cpp; then
    echo "PASS: farneback.cpp has OPTFLOW_USE_INITIAL_FLOW handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: farneback.cpp missing OPTFLOW_USE_INITIAL_FLOW handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: farneback.cpp should NOT have BufferPool usage in calc()
if grep -q 'BufferPool pool(stream);' modules/cudaoptflow/src/farneback.cpp; then
    echo "FAIL: farneback.cpp has BufferPool (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: farneback.cpp does not have BufferPool (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: farneback.cpp calcImpl should NOT have CV_Assert for frame checks
if grep -A 2 'void FarnebackOpticalFlowImpl::calcImpl' modules/cudaoptflow/src/farneback.cpp | grep -q 'CV_Assert(frame0.channels() == 1'; then
    echo "FAIL: farneback.cpp calcImpl has frame assertions (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: farneback.cpp calcImpl does not have frame assertions (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: farneback.cpp calcImpl should NOT have flowx.create/flowy.create
if grep -A 10 'void FarnebackOpticalFlowImpl::calcImpl' modules/cudaoptflow/src/farneback.cpp | grep -q 'flowx.create(size, CV_32F);'; then
    echo "FAIL: farneback.cpp calcImpl has flowx.create (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: farneback.cpp calcImpl does not have flowx.create (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: test_optflow.cpp should have relaxed tolerance (different values for different flags)
if grep -q 'if (farn->getFlags() & cv::OPTFLOW_FARNEBACK_GAUSSIAN)' modules/cudaoptflow/test/test_optflow.cpp && \
   grep -q 'EXPECT_MAT_SIMILAR(flow, d_flow, 2e-2);' modules/cudaoptflow/test/test_optflow.cpp; then
    echo "PASS: test_optflow.cpp has flag-based tolerance (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_optflow.cpp missing flag-based tolerance (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: video/src/optflowgf.cpp should have OPTFLOW_USE_INITIAL_FLOW handling
if grep -q 'if (flags_ & OPTFLOW_USE_INITIAL_FLOW)' modules/video/src/optflowgf.cpp && \
   grep -q 'if (_flow0.empty() || _flow0.size() != _prev0.size()' modules/video/src/optflowgf.cpp; then
    echo "PASS: optflowgf.cpp has OPTFLOW_USE_INITIAL_FLOW handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: optflowgf.cpp missing OPTFLOW_USE_INITIAL_FLOW handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: video/src/optflowgf.cpp calc() should have OPTFLOW_USE_INITIAL_FLOW in FarnebackOpticalFlowImpl
if grep -A 25 'void FarnebackOpticalFlowImpl::calc' modules/video/src/optflowgf.cpp | grep -q 'if( flags_ & OPTFLOW_USE_INITIAL_FLOW )'; then
    echo "PASS: optflowgf.cpp FarnebackOpticalFlowImpl::calc has OPTFLOW_USE_INITIAL_FLOW (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: optflowgf.cpp FarnebackOpticalFlowImpl::calc missing OPTFLOW_USE_INITIAL_FLOW (buggy version)" >&2
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
