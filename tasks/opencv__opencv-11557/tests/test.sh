#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11557: Remove Intel CPU-specific OpenCL workarounds and simplify MVN layer

# Check 1: convolution_layer.cpp should have simplified CV_OCL_RUN at line ~969
if sed -n '965,975p' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'CV_OCL_RUN(IS_DNN_OPENCL_TARGET(preferableTarget),' && \
   ! sed -n '965,975p' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'OCL_PERFORMANCE_CHECK'; then
    echo "PASS: convolution_layer.cpp removes Intel-specific OpenCL check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp should remove Intel-specific OpenCL performance check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: elementwise_layers.cpp should have simplified CV_OCL_RUN at line ~176
if sed -n '172,182p' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'CV_OCL_RUN(IS_DNN_OPENCL_TARGET(this->preferableTarget),' && \
   ! sed -n '172,182p' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'OCL_PERFORMANCE_CHECK'; then
    echo "PASS: elementwise_layers.cpp removes Intel-specific OpenCL check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: elementwise_layers.cpp should remove Intel-specific OpenCL performance check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: pooling_layer.cpp should have simplified CV_OCL_RUN at line ~193
if sed -n '188,198p' modules/dnn/src/layers/pooling_layer.cpp | grep -q 'CV_OCL_RUN(IS_DNN_OPENCL_TARGET(preferableTarget),' && \
   ! sed -n '188,198p' modules/dnn/src/layers/pooling_layer.cpp | grep -q 'OCL_PERFORMANCE_CHECK'; then
    echo "PASS: pooling_layer.cpp removes Intel-specific OpenCL check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pooling_layer.cpp should remove Intel-specific OpenCL performance check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: mvn_layer.cpp should have simplified CV_OCL_RUN at line ~254
if sed -n '248,258p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'CV_OCL_RUN(IS_DNN_OPENCL_TARGET(preferableTarget),' && \
   ! sed -n '248,258p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'OCL_PERFORMANCE_CHECK'; then
    echo "PASS: mvn_layer.cpp removes Intel-specific OpenCL check in forward()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp should remove Intel-specific OpenCL performance check in forward()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: mvn_layer.cpp should have simplified tryFuse() at line ~73
if sed -n '70,80p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'if (!fuse_batch_norm)' && \
   ! sed -n '70,80p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'preferableTarget == DNN_TARGET_OPENCL'; then
    echo "PASS: mvn_layer.cpp removes preferableTarget check from tryFuse()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp should change 'if (preferableTarget == DNN_TARGET_OPENCL && !fuse_batch_norm)' to 'if (!fuse_batch_norm)'" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: mvn_layer.cpp should have simplified code (Mat initialization before conditional)
if sed -n '273,285p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'Mat inpMat = inpBlob.reshape(1, newRows);' && \
   sed -n '273,285p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'Mat outMat = outBlob.reshape(1, newRows);'; then
    echo "PASS: mvn_layer.cpp has Mat initialization before conditional check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp should have Mat initialization before conditional" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: mvn_layer.cpp should have batch_norm fusion logic in single-value case
if sed -n '276,295p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'if (shift.empty())'; then
    echo "PASS: mvn_layer.cpp has batch_norm fusion logic in single-value case"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp should have batch_norm fusion in single-value MVN case" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: mvn_layer.cpp should have batch_norm variables and normalization logic
if sed -n '295,320p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'float weight = 1.f;' && \
   sed -n '295,320p' modules/dnn/src/layers/mvn_layer.cpp | grep -q 'normalizationScale'; then
    echo "PASS: mvn_layer.cpp has batch_norm fusion variables and normalization logic"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn_layer.cpp should have batch_norm fusion logic with normalizationScale" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: mvn.cl should use separate operations for squaring (not native_powr)
if sed -n '85,95p' modules/dnn/src/opencl/mvn.cl | grep -q 'vec_type dst_vec = src_vec - (vec_type)mean_val;' && \
   sed -n '85,95p' modules/dnn/src/opencl/mvn.cl | grep -q 'dst_vec = dst_vec \* dst_vec;'; then
    echo "PASS: mvn.cl uses separate subtract and multiply in CALC_MEAN"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn.cl should use separate operations instead of native_powr" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: mvn.cl should use separate operations in MEAN_FUSE
if sed -n '195,215p' modules/dnn/src/opencl/mvn.cl | grep -q 'dot0 = convert_float4(a0) - (Dtype4)sum.x;' && \
   sed -n '195,215p' modules/dnn/src/opencl/mvn.cl | grep -q 'dot0 = dot0 \* dot0;'; then
    echo "PASS: mvn.cl uses separate operations in MEAN_FUSE"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: mvn.cl should use separate operations for squaring in MEAN_FUSE" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: test_tf_importer.cpp should ADD Intel CPU tolerance workaround
if sed -n '160,170p' modules/dnn/test/test_tf_importer.cpp | grep -q 'cv::ocl::Device d = cv::ocl::Device::getDefault();' && \
   sed -n '160,170p' modules/dnn/test/test_tf_importer.cpp | grep -q 'bool loosenFlag' && \
   sed -n '160,170p' modules/dnn/test/test_tf_importer.cpp | grep -q 'runTensorFlowNet("max_pool_odd_same", targetId, false, loosenFlag'; then
    echo "PASS: test_tf_importer.cpp adds Intel CPU tolerance workaround"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should add loosenFlag for Intel CPU tolerance" >&2
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
