#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp"

checks_passed=0
checks_failed=0

# Check 1: In openvino file, test_nonzero_example should have SKIP (not "// no filter") in fixed version
if [ -f "modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp" ]; then
    if grep -A 1 'CASE(test_nonzero_example)' modules/dnn/test/test_onnx_conformance_layer_filter__openvino.inl.hpp | grep -q 'SKIP;'; then
        echo "PASS: test_onnx_conformance_layer_filter__openvino.inl.hpp has test_nonzero_example with SKIP (fixed version)"
        checks_passed=$((checks_passed + 1))
    else
        echo "FAIL: test_onnx_conformance_layer_filter__openvino.inl.hpp has test_nonzero_example without SKIP (buggy version)" >&2
        checks_failed=$((checks_failed + 1))
    fi
else
    echo "FAIL: test_onnx_conformance_layer_filter__openvino.inl.hpp missing" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: In classic denylist, "test_nonzero_example" should be present (fixed version)
if [ -f "modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp" ]; then
    if grep -q '"test_nonzero_example"' modules/dnn/test/test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp; then
        echo "PASS: test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp has test_nonzero_example entry (fixed version)"
        checks_passed=$((checks_passed + 1))
    else
        echo "FAIL: test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp missing test_nonzero_example entry (buggy version)" >&2
        checks_failed=$((checks_failed + 1))
    fi
else
    echo "FAIL: test_onnx_conformance_layer_filter_opencv_classic_denylist.inl.hpp missing" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: In parser denylist, "test_nonzero_example" should NOT be present (fixed version removes it)
if [ -f "modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp" ]; then
    if ! grep -q '"test_nonzero_example"' modules/dnn/test/test_onnx_conformance_layer_parser_denylist.inl.hpp; then
        echo "PASS: test_onnx_conformance_layer_parser_denylist.inl.hpp does not have test_nonzero_example entry (fixed version)"
        checks_passed=$((checks_passed + 1))
    else
        echo "FAIL: test_onnx_conformance_layer_parser_denylist.inl.hpp has test_nonzero_example entry (buggy version)" >&2
        checks_failed=$((checks_failed + 1))
    fi
else
    echo "FAIL: test_onnx_conformance_layer_parser_denylist.inl.hpp missing" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: NonZeroLayer class should be declared in all_layers.hpp (fixed version)
if grep -q 'class CV_EXPORTS NonZeroLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp declares NonZeroLayer class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing NonZeroLayer class declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: NonZero layer should be registered in init.cpp (fixed version)
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(NonZero,' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp registers NonZero layer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing NonZero layer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: nonzero_layer.cpp implementation file should exist (fixed version)
if [ -f "modules/dnn/src/layers/nonzero_layer.cpp" ]; then
    echo "PASS: nonzero_layer.cpp implementation exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: nonzero_layer.cpp missing (buggy version)" >&2
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
