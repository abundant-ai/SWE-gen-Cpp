#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# The fix restores the removePhaseSwitches function and related code that was removed in the buggy version.
# We validate by checking source files for the fixed state.

# Check 1: tf_graph_simplifier.cpp should have #include <queue> (fixed version)
if grep -q "#include <queue>" modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: tf_graph_simplifier.cpp includes <queue> (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp missing <queue> include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tf_graph_simplifier.cpp should have removePhaseSwitches function (fixed version)
if grep -q "void removePhaseSwitches(tensorflow::GraphDef& net)" modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: tf_graph_simplifier.cpp has removePhaseSwitches function (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp missing removePhaseSwitches function (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_graph_simplifier.hpp should declare removePhaseSwitches (fixed version)
if grep -q "void removePhaseSwitches(tensorflow::GraphDef& net);" modules/dnn/src/tensorflow/tf_graph_simplifier.hpp; then
    echo "PASS: tf_graph_simplifier.hpp declares removePhaseSwitches (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.hpp missing removePhaseSwitches declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tf_importer.cpp should call removePhaseSwitches (fixed version)
if grep -q "removePhaseSwitches(netBin);" modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: tf_importer.cpp calls removePhaseSwitches (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_importer.cpp missing removePhaseSwitches call (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: tf_graph_simplifier.cpp should NOT have the debug comment (fixed version removes it)
if ! grep -q "// std::cout << net.node(nodeToAdd).name()" modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: tf_graph_simplifier.cpp does not have debug comment (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tf_graph_simplifier.cpp has debug comment (buggy version)" >&2
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
