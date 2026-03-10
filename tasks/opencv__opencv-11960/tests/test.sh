#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #11960: Fix PriorBox layer for OpenCL targets

# Check 1: prior_box.cl should have the clip kernel
if grep -q '__kernel void clip' modules/dnn/src/opencl/prior_box.cl 2>/dev/null; then
    echo "PASS: prior_box.cl has clip kernel"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: prior_box.cl should have __kernel void clip function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: clip kernel should take nthreads parameter
if grep -q '__kernel void clip(const int nthreads,' modules/dnn/src/opencl/prior_box.cl 2>/dev/null; then
    echo "PASS: clip kernel has nthreads parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clip kernel should take 'const int nthreads' parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: clip kernel should take dst pointer
if grep -q '__global Dtype\* dst)' modules/dnn/src/opencl/prior_box.cl 2>/dev/null; then
    echo "PASS: clip kernel has dst pointer parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clip kernel should take '__global Dtype* dst' parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: clip kernel should use vload4
if grep -A8 '__kernel void clip' modules/dnn/src/opencl/prior_box.cl 2>/dev/null | grep -q 'vload4'; then
    echo "PASS: clip kernel uses vload4"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clip kernel should use vload4 to load data" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: clip kernel should use clamp
if grep -A8 '__kernel void clip' modules/dnn/src/opencl/prior_box.cl 2>/dev/null | grep -q 'clamp'; then
    echo "PASS: clip kernel uses clamp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clip kernel should use clamp function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: clip kernel should use vstore4
if grep -A8 '__kernel void clip' modules/dnn/src/opencl/prior_box.cl 2>/dev/null | grep -q 'vstore4'; then
    echo "PASS: clip kernel uses vstore4"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: clip kernel should use vstore4 to store data" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: prior_box_layer.cpp should use ocl::Kernel for clipping
if grep -A10 'if (_clip)' modules/dnn/src/layers/prior_box_layer.cpp 2>/dev/null | grep -q 'ocl::Kernel kernel("clip"'; then
    echo "PASS: prior_box_layer.cpp uses OpenCL kernel for clipping"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: prior_box_layer.cpp should use ocl::Kernel for clip operation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: prior_box_layer.cpp should calculate nthreads for kernel
if grep -A10 'if (_clip)' modules/dnn/src/layers/prior_box_layer.cpp 2>/dev/null | grep -q 'size_t nthreads'; then
    echo "PASS: prior_box_layer.cpp calculates nthreads"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: prior_box_layer.cpp should calculate nthreads for kernel" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: prior_box_layer.cpp should call kernel.run
if grep -A8 'if (_clip)' modules/dnn/src/layers/prior_box_layer.cpp 2>/dev/null | grep -q '.run(1, &nthreads'; then
    echo "PASS: prior_box_layer.cpp calls kernel.run"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: prior_box_layer.cpp should call kernel.run to execute clip kernel" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: prior_box_layer.cpp should NOT use CPU loop with getMat
if ! grep -A8 'if (_clip)' modules/dnn/src/layers/prior_box_layer.cpp 2>/dev/null | grep -q 'Mat mat = outputs\[0\].getMat(ACCESS_READ)'; then
    echo "PASS: prior_box_layer.cpp does not use CPU loop for clipping"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: prior_box_layer.cpp should not use CPU loop (getMat) for clipping" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: Verify OpenCL kernel is properly instantiated with prior_box_oclsrc
if grep -B2 -A8 'if (_clip)' modules/dnn/src/layers/prior_box_layer.cpp 2>/dev/null | grep -q 'ocl::dnn::prior_box_oclsrc'; then
    echo "PASS: prior_box_layer.cpp uses prior_box_oclsrc for OpenCL kernel"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: prior_box_layer.cpp should use ocl::dnn::prior_box_oclsrc for kernel source" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_layers.cpp should NOT skip test for OPENCL (only backend check)
# In the fixed version, we only skip for INFERENCE_ENGINE, not for OPENCL targets
if grep -A3 'TEST_P(Test_Caffe_layers, PriorBox_squares)' modules/dnn/test/test_layers.cpp 2>/dev/null | grep -q 'backend == DNN_BACKEND_INFERENCE_ENGINE' && \
   ! grep -A3 'TEST_P(Test_Caffe_layers, PriorBox_squares)' modules/dnn/test/test_layers.cpp 2>/dev/null | grep -q 'backend == DNN_BACKEND_OPENCV.*target == DNN_TARGET_OPENCL'; then
    echo "PASS: PriorBox_squares only skips INFERENCE_ENGINE backend"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PriorBox_squares should only skip INFERENCE_ENGINE backend, not OpenCL targets" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_layers.cpp should have FP16 tolerance handling
if grep -A30 'TEST_P(Test_Caffe_layers, PriorBox_squares)' modules/dnn/test/test_layers.cpp 2>/dev/null | grep -q 'double l1 ='; then
    echo "PASS: PriorBox_squares has l1 tolerance variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PriorBox_squares should have l1 tolerance variable for FP16" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: test_layers.cpp should check for OPENCL_FP16 in tolerance
if grep -A30 'TEST_P(Test_Caffe_layers, PriorBox_squares)' modules/dnn/test/test_layers.cpp 2>/dev/null | grep -q 'DNN_TARGET_OPENCL_FP16'; then
    echo "PASS: PriorBox_squares checks for OPENCL_FP16 in tolerance"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PriorBox_squares should check for DNN_TARGET_OPENCL_FP16 in tolerance" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: test_layers.cpp should use normAssert with l1 tolerance
if grep -A30 'TEST_P(Test_Caffe_layers, PriorBox_squares)' modules/dnn/test/test_layers.cpp 2>/dev/null | grep -q 'normAssert(out.reshape(1, 4), ref, "", l1)'; then
    echo "PASS: PriorBox_squares uses normAssert with l1 tolerance"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PriorBox_squares should use normAssert with l1 tolerance parameter" >&2
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
