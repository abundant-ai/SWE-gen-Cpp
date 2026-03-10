#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12188: Fix TensorFlow importer for Object Detection API models
# The fix restores critical functions for TensorFlow graph import that were removed

# Check 1: dnn.hpp should have writeTextGraph function declaration
if grep -q 'CV_EXPORTS_W void writeTextGraph' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has writeTextGraph function declaration"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp should have writeTextGraph function declaration" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: writeTextGraph should have model parameter
if grep -q 'writeTextGraph(const String& model, const String& output)' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: writeTextGraph has correct parameters"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: writeTextGraph should have model and output parameters" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_graph_simplifier.cpp should have permute function
if grep -q 'static void permute(google::protobuf::RepeatedPtrField<tensorflow::NodeDef>\* data' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: tf_graph_simplifier.cpp has permute function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp should have permute function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: permute function should use SwapElements
if grep -q 'SwapElements' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: permute function uses SwapElements"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: permute function should use SwapElements" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: tf_graph_simplifier.cpp should have sortByExecutionOrder function
if grep -q 'void sortByExecutionOrder(tensorflow::GraphDef& net)' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: tf_graph_simplifier.cpp has sortByExecutionOrder function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp should have sortByExecutionOrder function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: sortByExecutionOrder should use nodesMap
if grep -q 'std::map<std::string, int> nodesMap' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: sortByExecutionOrder uses nodesMap"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: sortByExecutionOrder should use nodesMap" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: sortByExecutionOrder should handle edges
if grep -q 'std::vector<std::vector<int> > edges' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: sortByExecutionOrder handles edges"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: sortByExecutionOrder should handle edges" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: sortByExecutionOrder should handle Merge nodes
if grep -q 'node.op() == "Merge" || node.op() == "RefMerge"' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: sortByExecutionOrder handles Merge nodes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: sortByExecutionOrder should handle Merge nodes" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: permute should handle elemIdToPos mapping
if grep -q 'elemIdToPos' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: permute uses elemIdToPos mapping"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: permute should use elemIdToPos mapping" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: permute should handle posToElemId mapping
if grep -q 'posToElemId' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: permute uses posToElemId mapping"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: permute should use posToElemId mapping" >&2
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
