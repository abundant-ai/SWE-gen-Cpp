#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# The fix removes pooling optimization and adds proper backend support guards
# We validate by checking source files for the fixed state

# Check 1: dnn.cpp should NOT have the pooling optimization after unsetAttached (fixed version removes it)
if ! grep -A 5 "currLayer->unsetAttached();" modules/dnn/src/dnn.cpp | grep -q "Ptr<PoolingLayer> poolingLayer = currLayer.dynamicCast<PoolingLayer>()"; then
    echo "PASS: dnn.cpp does not have pooling optimization after unsetAttached (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp has pooling optimization after unsetAttached (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.cpp should NOT have the computeMaxIdx optimization (buggy version has it)
if ! grep -q "poolingLayer->computeMaxIdx = false;" modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp does not have computeMaxIdx optimization (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp has computeMaxIdx optimization (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp should say "optimization #2" not "#3" for concat layer (fixed removes extra optimization)
if grep -q "// the optimization #2. if there is concat layer" modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp has 'optimization #2' for concat layer (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp has 'optimization #3' for concat layer (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: elementwise_layers.cpp ReLUFunctor should have #ifdef HAVE_INF_ENGINE guard (fixed version)
if grep -A 200 "struct ReLUFunctor" modules/dnn/src/layers/elementwise_layers.cpp | grep -A 20 "bool supportBackend" | grep -q "#ifdef HAVE_INF_ENGINE"; then
    echo "PASS: ReLUFunctor has #ifdef HAVE_INF_ENGINE guard (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ReLUFunctor missing #ifdef HAVE_INF_ENGINE guard (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: elementwise_layers.cpp AbsValFunctor should have #ifdef HAVE_INF_ENGINE guard (fixed version)
if grep -A 200 "struct AbsValFunctor" modules/dnn/src/layers/elementwise_layers.cpp | grep -A 20 "bool supportBackend" | grep -q "#ifdef HAVE_INF_ENGINE"; then
    echo "PASS: AbsValFunctor has #ifdef HAVE_INF_ENGINE guard (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: AbsValFunctor missing #ifdef HAVE_INF_ENGINE guard (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: flatten_layer.cpp should have (size_t) cast for axis parameter (fixed version)
if grep -q 'getParameters().*axis.*size_t' modules/dnn/src/layers/flatten_layer.cpp; then
    echo "PASS: flatten_layer.cpp has (size_t) cast for axis parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: flatten_layer.cpp missing (size_t) cast for axis parameter (buggy version)" >&2
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
