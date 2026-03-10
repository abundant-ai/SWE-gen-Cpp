#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state with fixed versions)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.cpp" "modules/dnn/test/test_common.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.impl.hpp" "modules/dnn/test/test_common.impl.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"

checks_passed=0
checks_failed=0

# The fix REVERTS a previous refactoring that moved test_common.impl.hpp content into test_common.cpp.
# The buggy state (after bug.patch) has the refactored structure.
# The fixed state (after fix.patch) restores the original structure with separate .impl.hpp file.

# Check 1: test_common.impl.hpp should exist (restored in the fix)
if [ -f modules/dnn/test/test_common.impl.hpp ]; then
    echo "PASS: test_common.impl.hpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_common.impl.hpp deleted (buggy refactored version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: test_common.cpp should include test_common.impl.hpp (fixed version)
if grep -q '#include "test_common.impl.hpp"' modules/dnn/test/test_common.cpp; then
    echo "PASS: test_common.cpp includes test_common.impl.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_common.cpp does not include test_common.impl.hpp (buggy refactored version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_common.cpp should NOT contain full implementation (it should be in .impl.hpp)
if grep -q 'void PrintTo(const cv::dnn::Backend& v, std::ostream\* os)' modules/dnn/test/test_common.cpp; then
    echo "FAIL: test_common.cpp has inline implementation (buggy refactored version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: test_common.cpp does not have inline implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: CMakeLists.txt should reference test_common.impl.hpp (fixed version)
if grep -q 'test_common.impl.hpp' modules/dnn/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt references test_common.impl.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt does not reference test_common.impl.hpp (buggy refactored version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: perf/perf_common.cpp should exist (restored in the fix)
if [ -f modules/dnn/perf/perf_common.cpp ]; then
    echo "PASS: perf_common.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_common.cpp deleted (buggy refactored version)" >&2
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
