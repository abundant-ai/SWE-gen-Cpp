#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/ts/src"
cp "/tests/modules/ts/src/ocl_test.cpp" "modules/ts/src/ocl_test.cpp"

checks_passed=0
checks_failed=0

# PR #12067: Test framework refactoring and CPU features reporting

# Check 1: getCPUFeaturesLine should be declared in utility.hpp
if grep -q 'CV_EXPORTS std::string getCPUFeaturesLine' modules/core/include/opencv2/core/utility.hpp 2>/dev/null; then
    echo "PASS: utility.hpp declares getCPUFeaturesLine function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: utility.hpp should declare getCPUFeaturesLine function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: getCPUFeaturesLine should be implemented in system.cpp
if grep -q 'std::string getCPUFeaturesLine()' modules/core/src/system.cpp 2>/dev/null; then
    echo "PASS: system.cpp implements getCPUFeaturesLine function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: system.cpp should implement getCPUFeaturesLine function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: CV_CPU_DISPATCH_FEATURES should be defined in OpenCVCompilerOptimizations.cmake
if grep -q 'CV_CPU_DISPATCH_FEATURES' cmake/OpenCVCompilerOptimizations.cmake 2>/dev/null; then
    echo "PASS: OpenCVCompilerOptimizations.cmake defines CV_CPU_DISPATCH_FEATURES"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCVCompilerOptimizations.cmake should define CV_CPU_DISPATCH_FEATURES" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: SystemInfoCollector class should be declared in ts.hpp
if grep -q 'class SystemInfoCollector' modules/ts/include/opencv2/ts.hpp 2>/dev/null; then
    echo "PASS: ts.hpp declares SystemInfoCollector class"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.hpp should declare SystemInfoCollector class" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: SystemInfoCollector::OnTestProgramStart should be implemented in ts.cpp
if grep -q 'void SystemInfoCollector::OnTestProgramStart' modules/ts/src/ts.cpp 2>/dev/null; then
    echo "PASS: ts.cpp implements SystemInfoCollector::OnTestProgramStart"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.cpp should implement SystemInfoCollector::OnTestProgramStart" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: ts.cpp should call getCPUFeaturesLine
if grep -q 'getCPUFeaturesLine()' modules/ts/src/ts.cpp 2>/dev/null; then
    echo "PASS: ts.cpp calls getCPUFeaturesLine"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.cpp should call getCPUFeaturesLine" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: ts.hpp should use SystemInfoCollector in test main
if grep -q 'new SystemInfoCollector' modules/ts/include/opencv2/ts.hpp 2>/dev/null; then
    echo "PASS: ts.hpp uses SystemInfoCollector in test main"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.hpp should use SystemInfoCollector in test main" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: printVersionInfo should be removed from ts_func.cpp
if ! grep -q 'void printVersionInfo' modules/ts/src/ts_func.cpp 2>/dev/null; then
    echo "PASS: printVersionInfo removed from ts_func.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: printVersionInfo should be removed from ts_func.cpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: ts.hpp should NOT call printVersionInfo
if ! grep -q 'cvtest::printVersionInfo' modules/ts/include/opencv2/ts.hpp 2>/dev/null; then
    echo "PASS: ts.hpp does not call printVersionInfo"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts.hpp should not call printVersionInfo" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: ts_perf.hpp should use SystemInfoCollector
if grep -q 'new cvtest::SystemInfoCollector' modules/ts/include/opencv2/ts/ts_perf.hpp 2>/dev/null; then
    echo "PASS: ts_perf.hpp uses SystemInfoCollector"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ts_perf.hpp should use SystemInfoCollector" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: TS constructor/destructor should be private
if grep -B2 'TS();' modules/ts/include/opencv2/ts.hpp 2>/dev/null | grep -v 'public:' | grep 'TS();' >/dev/null 2>&1; then
    echo "PASS: TS constructor is not in public section"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: TS constructor should not be in public section" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: get_file_storage should be removed from TS class
if ! grep -q 'CvFileStorage\* get_file_storage' modules/ts/include/opencv2/ts.hpp 2>/dev/null; then
    echo "PASS: get_file_storage removed from ts.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: get_file_storage should be removed from ts.hpp" >&2
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
