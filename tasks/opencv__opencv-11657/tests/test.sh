#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests FIRST (before applying fix.patch)
# The bug.patch reverted test files to buggy state, so we restore them to HEAD
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

# Now apply fix.patch to restore source files to HEAD state
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

checks_passed=0
checks_failed=0

# PR #11657: Share InferenceEngine plugin between multiple networks

# Check 1: op_inf_engine.cpp should have sharedPlugins map for plugin sharing
if grep -q 'static std::map<std::string, InferenceEngine::InferenceEnginePluginPtr> sharedPlugins' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp has sharedPlugins map for plugin sharing"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should have sharedPlugins map" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: op_inf_engine.cpp should check if plugin already exists in map
if grep -q 'pluginIt = sharedPlugins.find' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp checks for existing plugins in map"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should check for existing plugins" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: op_inf_engine.cpp should reuse plugin from map if found
if grep -q 'enginePtr = pluginIt->second' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp reuses existing plugin from map"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should reuse existing plugin from map" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: op_inf_engine.cpp should store new plugins in map
if grep -q 'sharedPlugins\[deviceName\] = enginePtr' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp stores new plugins in map"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should store new plugins in map" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: op_inf_engine.cpp should use InferencePlugin wrapper
if grep -q 'plugin = InferenceEngine::InferencePlugin(enginePtr)' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp uses InferencePlugin wrapper"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should use InferencePlugin wrapper" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: op_inf_engine.cpp should use netExec and infRequest for execution
if grep -q 'netExec = plugin.LoadNetwork' modules/dnn/src/op_inf_engine.cpp && \
   grep -q 'infRequest = netExec.CreateInferRequest' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: op_inf_engine.cpp uses netExec and infRequest"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should use netExec and infRequest" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: op_inf_engine.cpp forward() should use infRequest.Infer()
if grep -A3 'void InfEngineBackendNet::forward()' modules/dnn/src/op_inf_engine.cpp | grep -q 'infRequest.Infer()'; then
    echo "PASS: op_inf_engine.cpp forward() uses infRequest.Infer()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp forward() should use infRequest.Infer()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: op_inf_engine.hpp should have enginePtr member variable
if grep -q 'InferenceEngine::InferenceEnginePluginPtr enginePtr' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp has enginePtr member"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp should have enginePtr member" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: op_inf_engine.hpp should have plugin member
if grep -q 'InferenceEngine::InferencePlugin plugin' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp has plugin member"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp should have plugin member" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: op_inf_engine.hpp should have netExec and infRequest members
if grep -q 'InferenceEngine::ExecutableNetwork netExec' modules/dnn/src/op_inf_engine.hpp && \
   grep -q 'InferenceEngine::InferRequest infRequest' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: op_inf_engine.hpp has netExec and infRequest members"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.hpp should have netExec and infRequest members" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: op_inf_engine.cpp isInitialized() should check enginePtr (not plugin)
if grep -A3 'bool InfEngineBackendNet::isInitialized()' modules/dnn/src/op_inf_engine.cpp | grep -q 'return (bool)enginePtr'; then
    echo "PASS: op_inf_engine.cpp isInitialized() checks enginePtr"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp isInitialized() should check enginePtr" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_layers.cpp should have the multiple_networks test
if grep -q 'TEST(Test_DLDT, multiple_networks)' modules/dnn/test/test_layers.cpp; then
    echo "PASS: test_layers.cpp has multiple_networks test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp should have multiple_networks test" >&2
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
