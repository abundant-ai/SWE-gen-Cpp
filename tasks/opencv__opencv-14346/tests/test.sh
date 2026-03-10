#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# Check 1: gcompiled_async.hpp should exist (new file in fixed version)
if [ -f "modules/gapi/include/opencv2/gapi/gcompiled_async.hpp" ]; then
    echo "PASS: gcompiled_async.hpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcompiled_async.hpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gcomputation_async.hpp should exist (new file in fixed version)
if [ -f "modules/gapi/include/opencv2/gapi/gcomputation_async.hpp" ]; then
    echo "PASS: gcomputation_async.hpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcomputation_async.hpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gasync.cpp should exist (source file in fixed version)
if [ -f "modules/gapi/src/executor/gasync.cpp" ]; then
    echo "PASS: gasync.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gasync.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: CMakeLists.txt should include gasync.cpp in the build (fixed version)
if grep -q 'src/executor/gasync.cpp' modules/gapi/CMakeLists.txt; then
    echo "PASS: CMakeLists.txt includes gasync.cpp (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt missing gasync.cpp (buggy version)" >&2
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
