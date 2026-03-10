#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #13608 fixes InfEngineBackendLayer to handle different input sizes properly
# HEAD (97c3bcb1b7298e875b97f05cede8bc34e118da14): Fixed version with CNNNetwork-based constructor
# BASE (after bug.patch): Buggy version with DataPtr-based constructor (doesn't handle size variations)
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: dnn.cpp should pass ieNet (CNNNetwork) to InfEngineBackendLayer constructor
if grep -q 'Ptr<Layer> cvLayer(new InfEngineBackendLayer(ieNet));' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp uses ieNet (CNNNetwork) in constructor (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing ieNet in constructor (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: op_inf_engine.cpp should NOT have DataPtr-based constructor (fixed version uses CNNNetwork)
if grep -q 'InfEngineBackendLayer::InfEngineBackendLayer(const InferenceEngine::DataPtr& output_)' modules/dnn/src/op_inf_engine.cpp; then
    echo "FAIL: op_inf_engine.cpp has DataPtr-based constructor (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: op_inf_engine.cpp does not have DataPtr-based constructor (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 3: op_inf_engine.cpp getMemoryShapes should use complex implementation with t_net.getInputShapes()
if grep -A 15 'bool InfEngineBackendLayer::getMemoryShapes' modules/dnn/src/op_inf_engine.cpp | grep -q 'InferenceEngine::ICNNNetwork::InputShapes inShapes = t_net.getInputShapes()' && \
   grep -A 25 'bool InfEngineBackendLayer::getMemoryShapes' modules/dnn/src/op_inf_engine.cpp | grep -q 'std::vector<size_t> dims = t_net.getOutputsInfo()\[name\]->getDims()'; then
    echo "PASS: op_inf_engine.cpp getMemoryShapes uses complex implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp getMemoryShapes missing complex implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: op_inf_engine.cpp should NOT have the simplified getMemoryShapes with output->dims
if grep -A 10 'bool InfEngineBackendLayer::getMemoryShapes' modules/dnn/src/op_inf_engine.cpp | grep -q 'std::vector<size_t> dims = output->dims;'; then
    echo "FAIL: op_inf_engine.cpp has simplified getMemoryShapes (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: op_inf_engine.cpp does not have simplified getMemoryShapes (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: op_inf_engine.hpp should have CNNNetwork-based constructor signature
if grep -q 'InfEngineBackendLayer(const InferenceEngine::CNNNetwork &t_net_)' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp has CNNNetwork-based constructor signature (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp missing CNNNetwork-based constructor signature (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: op_inf_engine.hpp should have CNNNetwork t_net member, not DataPtr output
if grep -A 20 'class InfEngineBackendLayer' modules/dnn/src/op_inf_engine.hpp | grep -q 'InferenceEngine::CNNNetwork t_net;' && \
   ! grep -A 20 'class InfEngineBackendLayer' modules/dnn/src/op_inf_engine.hpp | grep -q 'InferenceEngine::DataPtr output;'; then
    echo "PASS: op_inf_engine.hpp has CNNNetwork t_net member (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp has wrong member type (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_layers.cpp should have Test_DLDT_two_inputs_3dim with 4 parameters
if grep -q 'typedef testing::TestWithParam<tuple<int, int, Target, std::vector<int> > > Test_DLDT_two_inputs_3dim;' modules/dnn/test/test_layers.cpp && \
   grep -q 'TEST_P(Test_DLDT_two_inputs_3dim, as_IR)' modules/dnn/test/test_layers.cpp; then
    echo "PASS: test_layers.cpp has Test_DLDT_two_inputs_3dim (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp missing Test_DLDT_two_inputs_3dim (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_layers.cpp should use parametrized inpSize from GetParam(), not fixed array
if grep -A 12 'TEST_P(Test_DLDT_two_inputs_3dim, as_IR)' modules/dnn/test/test_layers.cpp | grep -q 'std::vector<int> inpSize = get<3>(GetParam());' && \
   grep -A 14 'TEST_P(Test_DLDT_two_inputs_3dim, as_IR)' modules/dnn/test/test_layers.cpp | grep -q 'Mat firstInp(3, inpSize.data(), firstInpType);'; then
    echo "PASS: test_layers.cpp uses parametrized inpSize (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp missing parametrized inpSize (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_layers.cpp should have list_sizes vector and INSTANTIATE with 4 parameters
if grep -q 'std::vector< std::vector<int> > list_sizes' modules/dnn/test/test_layers.cpp && \
   grep -A 3 'INSTANTIATE_TEST_CASE_P(.*Test_DLDT_two_inputs_3dim' modules/dnn/test/test_layers.cpp | grep -q 'testing::ValuesIn(list_sizes)'; then
    echo "PASS: test_layers.cpp has list_sizes and proper INSTANTIATE (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp missing list_sizes infrastructure (buggy version)" >&2
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
