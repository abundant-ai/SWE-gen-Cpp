#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #13784 fixes multiple issues across OpenCV modules
# HEAD (f414c16c13ffb8f9f2173873f838fc61da7123c9): Fixed version with proper implementations
# BASE (after bug.patch): Buggy version with removed typedefs, tests, and incorrect code
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: PtrStepSzus typedef should be present in cuda_types.hpp (fixed version)
if grep -q 'typedef PtrStepSz<unsigned short> PtrStepSzus;' modules/core/include/opencv2/core/cuda_types.hpp; then
    echo "PASS: PtrStepSzus typedef present in cuda_types.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PtrStepSzus typedef missing from cuda_types.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: PtrStepus typedef should be present in cuda_types.hpp (fixed version)
if grep -q 'typedef PtrStep<unsigned short> PtrStepus;' modules/core/include/opencv2/core/cuda_types.hpp; then
    echo "PASS: PtrStepus typedef present in cuda_types.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PtrStepus typedef missing from cuda_types.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Prior box layer should use setSteps (fixed version)
if grep -q 'ieLayer.setSteps({_stepY, _stepX});' modules/dnn/src/layers/prior_box_layer.cpp; then
    echo "PASS: Prior box layer uses setSteps in prior_box_layer.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Prior box layer missing setSteps in prior_box_layer.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: getSharedPlugins function should exist (fixed version)
if grep -q 'static std::map<InferenceEngine::TargetDevice, InferenceEngine::InferenceEnginePluginPtr>& getSharedPlugins()' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: getSharedPlugins function present in op_inf_engine.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: getSharedPlugins function missing from op_inf_engine.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: AutoLock should be used in initPlugin (fixed version)
if grep -q 'AutoLock lock(getInitializationMutex());' modules/dnn/src/op_inf_engine.cpp && \
   grep -A 1 'AutoLock lock(getInitializationMutex());' modules/dnn/src/op_inf_engine.cpp | grep -q 'auto& sharedPlugins = getSharedPlugins();'; then
    echo "PASS: AutoLock and getSharedPlugins used in initPlugin (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: AutoLock or getSharedPlugins missing from initPlugin (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: MobileNet_SSD_Caffe_Different_Width_Height test should be present (fixed version)
if grep -q 'TEST_P(DNNTestNetwork, MobileNet_SSD_Caffe_Different_Width_Height)' modules/dnn/test/test_backends.cpp; then
    echo "PASS: MobileNet_SSD_Caffe_Different_Width_Height test present (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD_Caffe_Different_Width_Height test missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: MobileNet_SSD_v1_TensorFlow_Different_Width_Height test should be present (fixed version)
if grep -q 'TEST_P(DNNTestNetwork, MobileNet_SSD_v1_TensorFlow_Different_Width_Height)' modules/dnn/test/test_backends.cpp; then
    echo "PASS: MobileNet_SSD_v1_TensorFlow_Different_Width_Height test present (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MobileNet_SSD_v1_TensorFlow_Different_Width_Height test missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: #include <thread> should be present in test_layers.cpp (fixed version)
if grep -q '#include <thread>' modules/dnn/test/test_layers.cpp; then
    echo "PASS: #include <thread> present in test_layers.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: #include <thread> missing from test_layers.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: multithreading test should be present in test_layers.cpp (fixed version)
if grep -q 'TEST_P(Layer_Test_Convolution_DLDT, multithreading)' modules/dnn/test/test_layers.cpp; then
    echo "PASS: multithreading test present in test_layers.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: multithreading test missing from test_layers.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: CvtMode16U enum should be present in perf_cvt_color.cpp (fixed version)
if grep -q 'CV_ENUM(CvtMode16U,' modules/imgproc/perf/perf_cvt_color.cpp; then
    echo "PASS: CvtMode16U enum present in perf_cvt_color.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CvtMode16U enum missing from perf_cvt_color.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: CvtMode32F enum should be present in perf_cvt_color.cpp (fixed version)
if grep -q 'CV_ENUM(CvtMode32F,' modules/imgproc/perf/perf_cvt_color.cpp; then
    echo "PASS: CvtMode32F enum present in perf_cvt_color.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CvtMode32F enum missing from perf_cvt_color.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: CLAHE perf test should have MatType parameter (fixed version)
if grep -q 'typedef tuple<Size, double, MatType> Sz_ClipLimit_t;' modules/imgproc/perf/perf_histogram.cpp; then
    echo "PASS: CLAHE perf test has MatType parameter in perf_histogram.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CLAHE perf test missing MatType parameter in perf_histogram.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: Morph code should use 'i - i % cn' (fixed version)
if grep -q 'return i - i % cn;' modules/imgproc/src/morph.cpp; then
    echo "PASS: Morph code uses 'i - i % cn' in morph.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Morph code doesn't use 'i - i % cn' in morph.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: CamShift should have std::max calls (fixed version)
if grep -q 'rotate_a = std::max(0.0, rotate_a);' modules/video/src/camshift.cpp && \
   grep -q 'rotate_c = std::max(0.0, rotate_c);' modules/video/src/camshift.cpp; then
    echo "PASS: CamShift has std::max calls in camshift.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CamShift missing std::max calls in camshift.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: Python script should have nodesToKeep list (fixed version)
if grep -q 'nodesToKeep = \[\]' samples/dnn/tf_text_graph_mask_rcnn.py; then
    echo "PASS: Python script has nodesToKeep list (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Python script missing nodesToKeep list (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: Python script should have getUnconnectedNodes function (fixed version)
if grep -q 'def getUnconnectedNodes():' samples/dnn/tf_text_graph_mask_rcnn.py; then
    echo "PASS: Python script has getUnconnectedNodes function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Python script missing getUnconnectedNodes function (buggy version)" >&2
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
