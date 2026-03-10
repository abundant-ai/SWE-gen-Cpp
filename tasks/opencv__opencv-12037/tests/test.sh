#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"

checks_passed=0
checks_failed=0

# PR #12037: Add tests for Intel Inference Engine models

# Check 1: test_ie_models.cpp file should exist (was deleted in bug.patch, added in fix)
if [ -f "modules/dnn/test/test_ie_models.cpp" ]; then
    echo "PASS: test_ie_models.cpp file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_ie_models.cpp file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: CMakeLists.txt should have Inference Engine test configuration
if grep -q "Test Intel's Inference Engine models" modules/dnn/CMakeLists.txt 2>/dev/null && \
   grep -q "HAVE_INF_ENGINE AND TARGET opencv_test_dnn" modules/dnn/CMakeLists.txt 2>/dev/null; then
    echo "PASS: CMakeLists.txt has Inference Engine test configuration"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should have Inference Engine test configuration" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: CMakeLists.txt should include Inference Engine include directories
if grep -q "ocv_target_include_directories(opencv_test_dnn PRIVATE \${INF_ENGINE_INCLUDE_DIRS})" modules/dnn/CMakeLists.txt 2>/dev/null; then
    echo "PASS: CMakeLists.txt includes Inference Engine directories"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should include Inference Engine directories" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: CMakeLists.txt should link Inference Engine libraries
if grep -q "ocv_target_link_libraries(opencv_test_dnn LINK_PRIVATE \${INF_ENGINE_LIBRARIES})" modules/dnn/CMakeLists.txt 2>/dev/null; then
    echo "PASS: CMakeLists.txt links Inference Engine libraries"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should link Inference Engine libraries" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: op_inf_engine.cpp should use TargetDevice as map key (not string)
if grep -q "static std::map<InferenceEngine::TargetDevice, InferenceEngine::InferenceEnginePluginPtr> sharedPlugins;" modules/dnn/src/op_inf_engine.cpp 2>/dev/null; then
    echo "PASS: op_inf_engine.cpp uses TargetDevice as map key"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should use TargetDevice as map key" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: op_inf_engine.cpp should directly find using targetDevice
if grep -q "auto pluginIt = sharedPlugins.find(targetDevice);" modules/dnn/src/op_inf_engine.cpp 2>/dev/null; then
    echo "PASS: op_inf_engine.cpp finds plugin using targetDevice"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should find plugin using targetDevice" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: op_inf_engine.cpp should store plugin with targetDevice key
if grep -q "sharedPlugins\[targetDevice\] = enginePtr;" modules/dnn/src/op_inf_engine.cpp 2>/dev/null; then
    echo "PASS: op_inf_engine.cpp stores plugin with targetDevice key"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: op_inf_engine.cpp should store plugin with targetDevice key" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: ts.hpp should include ValuesIn from gtest
if grep -q "using testing::ValuesIn;" modules/ts/include/opencv2/ts.hpp 2>/dev/null; then
    echo "PASS: ts.hpp includes ValuesIn"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.hpp should include ValuesIn" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: ts.hpp should declare findDataDirectory function
if grep -q "std::string findDataDirectory(const std::string& relative_path, bool required = true);" modules/ts/include/opencv2/ts.hpp 2>/dev/null; then
    echo "PASS: ts.hpp declares findDataDirectory function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.hpp should declare findDataDirectory function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: ts.cpp should implement findDataDirectory function
if grep -q "std::string findDataDirectory(const std::string& relative_path, bool required)" modules/ts/src/ts.cpp 2>/dev/null; then
    echo "PASS: ts.cpp implements findDataDirectory function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.cpp should implement findDataDirectory function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: ts.cpp should have findData helper that handles both files and directories
if grep -q "static std::string findData(const std::string& relative_path, bool required, bool findDirectory)" modules/ts/src/ts.cpp 2>/dev/null; then
    echo "PASS: ts.cpp has findData helper function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.cpp should have findData helper function" >&2
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
