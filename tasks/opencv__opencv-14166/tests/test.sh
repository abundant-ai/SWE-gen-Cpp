#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state with fixed versions)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"

checks_passed=0
checks_failed=0

# The fix adds SoftMaxSlimSubgraph class and its usage
# The buggy state (after bug.patch) has them removed
# The fixed state (after copying HEAD files) has them present

# Check 1: tf_graph_simplifier.cpp SHOULD have SoftMaxSlimSubgraph class in fixed version
if grep -q 'class SoftMaxSlimSubgraph' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: SoftMaxSlimSubgraph class exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SoftMaxSlimSubgraph class missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tf_graph_simplifier.cpp should register SoftMaxSlimSubgraph in fixed version
if grep -q 'subgraphs.push_back(Ptr<Subgraph>(new SoftMaxSlimSubgraph()))' modules/dnn/src/tensorflow/tf_graph_simplifier.cpp; then
    echo "PASS: SoftMaxSlimSubgraph registration exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: SoftMaxSlimSubgraph registration missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tf_importer.cpp should have sortByExecutionOrder call in fixed version
if grep -q 'sortByExecutionOrder(netBin)' modules/dnn/src/tensorflow/tf_importer.cpp; then
    echo "PASS: sortByExecutionOrder call exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: sortByExecutionOrder call missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: tf_importer.cpp should have proper braces around if block in fixed version
if grep -A 3 'if (!netTxt.ByteSize())' modules/dnn/src/tensorflow/tf_importer.cpp | grep -q '{'; then
    echo "PASS: Proper braces around if block (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Missing braces around if block (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: test_tf_importer.cpp should have slim_softmax test in fixed version
if grep -q 'runTensorFlowNet("slim_softmax")' modules/dnn/test/test_tf_importer.cpp; then
    echo "PASS: slim_softmax test exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: slim_softmax test missing (buggy version)" >&2
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
