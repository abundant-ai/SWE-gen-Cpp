#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12211: TensorFlow preprocessing fix and layer fusion improvements
# The fix adds tryFuse/getScaleShift methods to activation functors and updates preprocessing

# Check 1: CMakeLists.txt should pass INF_ENGINE_TARGET to perf tests
if grep -q 'ocv_add_perf_tests(${INF_ENGINE_TARGET})' modules/dnn/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt passes INF_ENGINE_TARGET to perf tests"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should pass INF_ENGINE_TARGET to perf tests" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.cpp should have OpenCL fusion check after backend check
if grep -A 8 'if (preferableBackend != DNN_BACKEND_OPENCV)' modules/dnn/src/dnn.cpp | grep -q 'TODO: OpenCL target support more fusion styles'; then
    echo "PASS: dnn.cpp has OpenCL fusion check in correct location"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should have OpenCL fusion check after backend check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: convolution_layer.cpp should use w_ and b_ parameters
if grep -q 'void fuseWeights(const Mat& w_, const Mat& b_)' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp uses w_ and b_ parameter names"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp should use w_ and b_ parameter names" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: convolution_layer.cpp should handle scalar expansion
if grep -q 'Mat w = w_.total() == 1 ? Mat(1, outCn, CV_32F, Scalar(w_.at<float>(0))) : w_;' modules/dnn/src/layers/convolution_layer.cpp; then
    echo "PASS: convolution_layer.cpp handles scalar expansion"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: convolution_layer.cpp should handle scalar expansion" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: ElementWiseLayer should have tryFuse override
if grep -q 'virtual bool tryFuse(Ptr<dnn::Layer>& top) CV_OVERRIDE' modules/dnn/src/layers/elementwise_layers.cpp; then
    echo "PASS: ElementWiseLayer has tryFuse override"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ElementWiseLayer should have tryFuse override" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: ElementWiseLayer should have getScaleShift override
if grep -q 'void getScaleShift(Mat& scale_, Mat& shift_) const CV_OVERRIDE' modules/dnn/src/layers/elementwise_layers.cpp; then
    echo "PASS: ElementWiseLayer has getScaleShift override"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ElementWiseLayer should have getScaleShift override" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Activation functors should have tryFuse methods
tryFuse_count=$(grep -c 'bool tryFuse' modules/dnn/src/layers/elementwise_layers.cpp || echo 0)
if [ "$tryFuse_count" -ge 8 ]; then
    echo "PASS: Activation functors have tryFuse methods"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Activation functors should have tryFuse methods (found $tryFuse_count)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: PowerFunctor should have tryFuse implementation
if grep -A 20 'struct PowerFunctor' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'bool tryFuse(Ptr<dnn::Layer>& top)' || \
   grep -B 30 'int64 getFLOPSPerElement() const { return power == 1 ? 2 : 10; }' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'bool tryFuse(Ptr<dnn::Layer>& top)'; then
    echo "PASS: PowerFunctor has tryFuse implementation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PowerFunctor should have tryFuse implementation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: PowerFunctor should have getScaleShift implementation
if grep -B 30 'int64 getFLOPSPerElement() const { return power == 1 ? 2 : 10; }' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'void getScaleShift(Mat& _scale, Mat& _shift) const'; then
    echo "PASS: PowerFunctor has getScaleShift implementation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PowerFunctor should have getScaleShift implementation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: PowerFunctor should check for identity transformation
if sed -n '/struct PowerFunctor/,/^struct [A-Z]/p' modules/dnn/src/layers/elementwise_layers.cpp | grep -q 'if (power == 1.0f && scale == 1.0f && shift == 0.0f)'; then
    echo "PASS: PowerFunctor checks for identity transformation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: PowerFunctor should check for identity transformation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: tf_text_graph_faster_rcnn.py should keep Preprocessor scopes
if grep -q "'Preprocessor/sub'," samples/dnn/tf_text_graph_faster_rcnn.py && \
   grep -q "'Preprocessor/mul'," samples/dnn/tf_text_graph_faster_rcnn.py; then
    echo "PASS: tf_text_graph_faster_rcnn.py keeps Preprocessor scopes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_faster_rcnn.py should keep Preprocessor scopes" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: tf_text_graph_ssd.py should keep 'Sub' in keepOps
if grep -q "'Sub']" samples/dnn/tf_text_graph_ssd.py; then
    echo "PASS: tf_text_graph_ssd.py keeps 'Sub' in keepOps"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should keep 'Sub' in keepOps" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: tf_text_graph_ssd.py should use 'Preprocessor/map' prefix
if grep -q "prefixesToRemove = ('MultipleGridAnchorGenerator/', 'Postprocessor/', 'Preprocessor/map')" samples/dnn/tf_text_graph_ssd.py; then
    echo "PASS: tf_text_graph_ssd.py uses 'Preprocessor/map' prefix"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_text_graph_ssd.py should use 'Preprocessor/map' prefix" >&2
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
