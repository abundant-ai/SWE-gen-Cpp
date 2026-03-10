#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_intersection.cpp" "modules/imgproc/test/test_intersection.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11567: Fix static analysis issues and test randomness

# Check 1: pyopencv_dnn.hpp should assert return values instead of ignoring them
if grep -q 'CV_Assert(pyopencv_to_generic_vec(res, outputs' modules/dnn/misc/python/pyopencv_dnn.hpp && \
   grep -q 'CV_Assert(pyopencv_to(res, pyOutputs' modules/dnn/misc/python/pyopencv_dnn.hpp; then
    echo "PASS: pyopencv_dnn.hpp properly asserts return values"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_dnn.hpp should assert return values with CV_Assert" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.cpp should have null checks for downLayerData
if grep -A3 'LayerData \*downLayerData = &layers\[eltwiseData->inputBlobsId\[1\].lid\];' modules/dnn/src/dnn.cpp | grep -q 'CV_Assert(downLayerData)'; then
    echo "PASS: dnn.cpp adds null checks for downLayerData"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should add CV_Assert(downLayerData) after initialization" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp should remove useless null check before convLayer assignment
if grep -q 'Ptr<ConvolutionLayer> convLayer = downLayerData->layerInstance.dynamicCast<ConvolutionLayer>()' modules/dnn/src/dnn.cpp && \
   ! grep -B2 'Ptr<ConvolutionLayer> convLayer = downLayerData->layerInstance.dynamicCast<ConvolutionLayer>()' modules/dnn/src/dnn.cpp | grep -q 'if( downLayerData )'; then
    echo "PASS: dnn.cpp removes useless null check before convLayer assignment"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should remove useless null check before convLayer assignment" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: recurrent_layers.cpp should use const int N to avoid repeated member access
if grep -q 'const int N = Wh.cols;' modules/dnn/src/layers/recurrent_layers.cpp && \
   grep -A3 'const int N = Wh.cols;' modules/dnn/src/layers/recurrent_layers.cpp | grep -q 'CV_Assert(blobs\[i\].rows == N && blobs\[i\].cols == N)'; then
    echo "PASS: recurrent_layers.cpp uses const int N for clarity"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: recurrent_layers.cpp should use const int N = Wh.cols" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: math_functions.cpp should initialize ret variable
if grep -q 'bool ret = true;' modules/dnn/src/ocl4dnn/src/math_functions.cpp; then
    echo "PASS: math_functions.cpp initializes ret variable"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: math_functions.cpp should initialize bool ret = true" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: color.hpp should initialize nArgs member in OclHelper constructor
if grep -A1 'OclHelper( InputArray _src, OutputArray _dst, int dcn)' modules/imgproc/src/color.hpp | grep -q 'nArgs(0)'; then
    echo "PASS: color.hpp initializes nArgs member in constructor"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: color.hpp should initialize nArgs(0) in OclHelper constructor" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_halide_layers.cpp should use cv::theRNG() for reproducible randomness
if grep -q 'cv::RNG& rng = cv::theRNG()' modules/dnn/test/test_halide_layers.cpp; then
    echo "PASS: test_halide_layers.cpp uses cv::theRNG() for reproducible randomness"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_halide_layers.cpp should use cv::theRNG() instead of rand()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_tf_importer.cpp should initialize members in ResizeBilinearLayer constructor
if grep -A1 'ResizeBilinearLayer(const LayerParams &params)' modules/dnn/test/test_tf_importer.cpp | grep -q 'outWidth(0), outHeight(0), factorWidth(1), factorHeight(1)'; then
    echo "PASS: test_tf_importer.cpp initializes ResizeBilinearLayer members"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should initialize outWidth, outHeight, factorWidth, factorHeight in constructor" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_intersection.cpp should use cv::theRNG() for reproducible randomness
if grep -q 'cv::RNG& rng = cv::theRNG()' modules/imgproc/test/test_intersection.cpp; then
    echo "PASS: test_intersection.cpp uses cv::theRNG() for reproducible randomness"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_intersection.cpp should use cv::theRNG() instead of rand()" >&2
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
