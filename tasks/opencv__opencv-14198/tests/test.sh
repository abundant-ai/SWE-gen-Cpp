#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state with fixed versions)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.cpp" "modules/dnn/test/test_common.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.impl.hpp" "modules/dnn/test/test_common.impl.hpp"

checks_passed=0
checks_failed=0

# The fix moves shared DNN test code from test_common.cpp into test_common.impl.hpp
# to avoid sharing .cpp files (PCH support is broken)
# The buggy state (after bug.patch) has code in test_common.cpp, no .impl.hpp
# The fixed state (after copying HEAD files) has code in test_common.impl.hpp

# Check 1: test_common.impl.hpp SHOULD exist in fixed version (code moved from .cpp)
if [ -f modules/dnn/test/test_common.impl.hpp ]; then
    echo "PASS: test_common.impl.hpp exists (fixed version - shared code in .hpp)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_common.impl.hpp missing (buggy version - code still in .cpp)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: test_common.impl.hpp should have actual implementation in fixed version
if grep -q 'void normAssert' modules/dnn/test/test_common.impl.hpp 2>/dev/null; then
    echo "PASS: test_common.impl.hpp has implementation code (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_common.impl.hpp missing implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_common.cpp SHOULD include test_common.impl.hpp in fixed version
if grep -q '#include "test_common.impl.hpp"' modules/dnn/test/test_common.cpp; then
    echo "PASS: test_common.cpp includes test_common.impl.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_common.cpp does not include test_common.impl.hpp (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: test_common.cpp should NOT have implementation (just includes) in fixed version
if ! grep -q 'void normAssert' modules/dnn/test/test_common.cpp; then
    echo "PASS: test_common.cpp has no implementation, just includes (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_common.cpp still has implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: perf_common.cpp SHOULD exist in fixed version
if [ -f modules/dnn/perf/perf_common.cpp ]; then
    echo "PASS: perf_common.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_common.cpp missing (buggy version - file was deleted)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: CMakeLists.txt should reference both test_common.cpp and .hpp/.impl.hpp (fixed version)
if grep -q 'FILES test_common "${CMAKE_CURRENT_LIST_DIR}/test/test_common.hpp"' modules/dnn/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt references test_common.hpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt does not reference test_common.hpp (buggy version)" >&2
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
