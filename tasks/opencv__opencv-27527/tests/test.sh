#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"

checks_passed=0
checks_failed=0

# Check 1: trilu_layer.cpp should exist (fixed version adds it)
if [ -f "modules/dnn/src/layers/trilu_layer.cpp" ]; then
    echo "PASS: trilu_layer.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: trilu_layer.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: TriluLayer should be declared in all_layers.hpp (fixed version)
if grep -q 'class CV_EXPORTS TriluLayer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: all_layers.hpp has TriluLayer declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: all_layers.hpp missing TriluLayer declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: TriluLayer should be registered in init.cpp (fixed version)
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(Trilu,' modules/dnn/src/init.cpp; then
    echo "PASS: init.cpp has TriluLayer registration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: init.cpp missing TriluLayer registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: parseTrilu should be declared in onnx_importer2.cpp (fixed version)
if grep -q 'void parseTrilu' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp has parseTrilu declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing parseTrilu declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Trilu dispatch should be registered in onnx_importer2.cpp (fixed version)
if grep -q 'dispatch\["Trilu"\]' modules/dnn/src/onnx/onnx_importer2.cpp; then
    echo "PASS: onnx_importer2.cpp has Trilu dispatch registration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer2.cpp missing Trilu dispatch registration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_onnx_importer.cpp should have trilu tests (fixed version)
if grep -q 'TEST_P(Test_ONNX_layers, trilu_' modules/dnn/test/test_onnx_importer.cpp; then
    echo "PASS: test_onnx_importer.cpp has trilu test cases (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_onnx_importer.cpp missing trilu test cases (buggy version)" >&2
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
