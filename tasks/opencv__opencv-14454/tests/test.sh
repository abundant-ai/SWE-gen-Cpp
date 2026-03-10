#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# Check 1: tf_graph_simplifier.cpp should have getInputNodeId (fixed version)
if grep -q 'static int getInputNodeId(const tensorflow::GraphDef& net,' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: tf_graph_simplifier.cpp has getInputNodeId function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp missing getInputNodeId function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tf_graph_simplifier.cpp should use queue-based matching (fixed version)
if grep -q 'std::queue<int> nodesToMatch;' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: tf_graph_simplifier.cpp uses queue-based matching (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp not using queue-based matching (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_graph_simplifier.cpp should have ReshapeAsShapeSubgraph after SoftMaxSlimV2Subgraph (fixed version)
if grep -A1 'SoftMaxSlimV2Subgraph' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp | grep -q 'ReshapeAsShapeSubgraph'; then
    echo "PASS: tf_graph_simplifier.cpp has correct subgraph ordering (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp has incorrect subgraph ordering (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tf_importer.cpp should have proper NHWC reshape handling (fixed version)
if grep -q 'if (inpLayout == DATA_LAYOUT_NHWC)' modules/dnn/src/tensorflow/tf_importer.cpp && \
   grep -q 'if (newShape.total() == 4)' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp has proper NHWC reshape handling (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp missing proper NHWC reshape handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_tf_importer.cpp should have subpixel test (fixed version)
if grep -q 'TEST_P(Test_TensorFlow_layers, subpixel)' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: test_tf_importer.cpp has subpixel test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp missing subpixel test (buggy version)" >&2
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
