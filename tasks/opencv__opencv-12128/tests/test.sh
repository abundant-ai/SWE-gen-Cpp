#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12128: Support TensorFlow Reshape with dynamic shape from a second input
# The fix adds support for two-input reshape mode in multiple files

# Check 1: reshape_layer.cpp should have conditional logic for inputs.size()
if grep -A 5 "if (inputs.size() == 1 || inputs.size() == requiredOutputs)" modules/dnn/src/layers/reshape_layer.cpp 2>/dev/null | grep -q "outputs.clear()"; then
    echo "PASS: reshape_layer.cpp has conditional logic for two-input mode"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reshape_layer.cpp should have conditional logic for two-input mode" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: reshape_layer.cpp should use outputs.size() in forward loop (not inputs.size())
if grep -q "for (size_t i = 0; i < outputs.size(); i++)" modules/dnn/src/layers/reshape_layer.cpp 2>/dev/null; then
    echo "PASS: reshape_layer.cpp uses outputs.size() in loop"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reshape_layer.cpp should use outputs.size() in loop" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: reshape_layer.cpp initInfEngine should accept inputs parameter and handle dynamic shape
if grep -q "virtual Ptr<BackendNode> initInfEngine(const std::vector<Ptr<BackendWrapper> >& inputs)" modules/dnn/src/layers/reshape_layer.cpp 2>/dev/null; then
    echo "PASS: reshape_layer.cpp initInfEngine accepts inputs parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reshape_layer.cpp initInfEngine should accept inputs parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: reshape_layer.cpp should have logic to get shape from second input
if grep -q "InferenceEngine::DataPtr shapeSrc = infEngineDataNode(inputs\[1\])" modules/dnn/src/layers/reshape_layer.cpp 2>/dev/null; then
    echo "PASS: reshape_layer.cpp has logic to get shape from second input"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reshape_layer.cpp should get shape from second input in initInfEngine" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: op_inf_engine.cpp should use reverse iterators (rbegin, rend)
if grep -q "std::vector<int> size(dims.rbegin(), dims.rend())" modules/dnn/src/op_inf_engine.cpp 2>/dev/null; then
    echo "PASS: op_inf_engine.cpp uses reverse iterators in infEngineBlobToMat"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should use reverse iterators (rbegin, rend)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: tf_graph_simplifier.cpp should have ReshapeAsShapeSubgraph class
if grep -q "class ReshapeAsShapeSubgraph : public Subgraph" modules/dnn/src/tensorflow/tf_graph_simplifier.cpp 2>/dev/null; then
    echo "PASS: tf_graph_simplifier.cpp has ReshapeAsShapeSubgraph class"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp should have ReshapeAsShapeSubgraph class" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: tf_graph_simplifier.cpp should register ReshapeAsShapeSubgraph
if grep -q "subgraphs.push_back(Ptr<Subgraph>(new ReshapeAsShapeSubgraph()))" modules/dnn/src/tensorflow/tf_graph_simplifier.cpp 2>/dev/null; then
    echo "PASS: tf_graph_simplifier.cpp registers ReshapeAsShapeSubgraph"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp should register ReshapeAsShapeSubgraph" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: tf_importer.cpp should have comment about two possible implementations
if grep -q "// There are two possible implementations: reshape an input using" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp has comment about two implementations"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should have comment about two implementations" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: tf_importer.cpp should check if shape input is constant
if grep -q "if (value_id.find(layer.input(1)) != value_id.end())" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp checks if shape input is constant"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should check if shape input is constant" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: tf_importer.cpp should connect two inputs in dynamic shape case
if grep -q "connect(layer_id, dstNet, parsePin(layer.input(1)), id, 1)" modules/dnn/src/tensorflow/tf_importer.cpp 2>/dev/null; then
    echo "PASS: tf_importer.cpp connects two inputs in dynamic shape case"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp should connect two inputs in dynamic shape case" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: test_tf_importer.cpp should have reshape_as_shape test
if grep -q 'runTensorFlowNet("reshape_as_shape")' modules/dnn/test/test_tf_importer.cpp 2>/dev/null; then
    echo "PASS: test_tf_importer.cpp has reshape_as_shape test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp should have reshape_as_shape test" >&2
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
