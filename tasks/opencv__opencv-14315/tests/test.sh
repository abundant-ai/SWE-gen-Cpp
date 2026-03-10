#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# Check 1: Test file in /tests should have slim_softmax_v2 test (fixed version)
if [ -f "/tests/modules/dnn/test/test_tf_importer.cpp" ] && grep -q "TEST_P(Test_TensorFlow_layers, slim_softmax_v2)" /tests/modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: slim_softmax_v2 test found in /tests/modules/dnn/test/test_tf_importer.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: slim_softmax_v2 test missing from /tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Test file in /tests should have squeeze test (fixed version)
if [ -f "/tests/modules/dnn/test/test_tf_importer.cpp" ] && grep -q "TEST_P(Test_TensorFlow_layers, squeeze)" /tests/modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: squeeze test found in /tests/modules/dnn/test/test_tf_importer.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: squeeze test missing from /tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: SoftMaxSlimV2Subgraph class should exist in tf_graph_simplifier.cpp (fixed version)
if grep -q "class SoftMaxSlimV2Subgraph : public Subgraph" modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: SoftMaxSlimV2Subgraph class found in tf_graph_simplifier.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SoftMaxSlimV2Subgraph class missing from tf_graph_simplifier.cpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: finalize method should exist in flatten_layer.cpp (fixed version)
if grep -q "void finalize(InputArrayOfArrays inputs_arr, OutputArrayOfArrays) CV_OVERRIDE" modules/dnn/src/layers/flatten_layer.cpp; then
    echo "PASS: finalize method found in flatten_layer.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: finalize method missing from flatten_layer.cpp (buggy version)" >&2
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
