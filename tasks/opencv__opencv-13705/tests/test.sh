#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_ptr.cpp" "modules/core/test/test_ptr.cpp"

checks_passed=0
checks_failed=0

# PR #13705 fixes clang warnings by:
# 1. Fixing enum shadowing in FileStorage (moving State enum to header)
# 2. Adding std::move where appropriate to avoid -Wreturn-std-move warnings
# 3. Removing need for -Wself-assign-overloaded suppressions in test_ptr.cpp
# HEAD (ea3dc789867564e3727cde46245e35577a0c5d80): Fixed version with all warning fixes
# BASE (after bug.patch): Buggy version with warning suppressions in test_ptr.cpp
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: persistence.hpp should have named enum State (fixed version)
if grep -q 'enum State' modules/core/include/opencv2/core/persistence.hpp; then
    echo "PASS: persistence.hpp has named enum State (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: persistence.hpp does not have named enum State (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: persistence.cpp should NOT have duplicate State enum (fixed version)
if ! grep -q 'enum State' modules/core/src/persistence.cpp; then
    echo "PASS: persistence.cpp does not have duplicate State enum (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: persistence.cpp has duplicate State enum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gcompoundkernel.hpp should use std::forward (fixed version)
if grep -q 'return std::forward<std::tuple<Objs...>>(objs);' modules/gapi/include/opencv2/gapi/gcompoundkernel.hpp; then
    echo "PASS: gcompoundkernel.hpp uses std::forward (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcompoundkernel.hpp does not use std::forward (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: camera.cpp should use std::move for return (fixed version)
if grep -q 'return std::move(k);' modules/stitching/src/camera.cpp; then
    echo "PASS: camera.cpp uses std::move for return (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: camera.cpp does not use std::move for return (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: optical_flow_io.cpp should use std::move for returns (fixed version, check one instance)
if grep -q 'return std::move(flow); // no file - return empty matrix' modules/video/src/optical_flow_io.cpp; then
    echo "PASS: optical_flow_io.cpp uses std::move for returns (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: optical_flow_io.cpp does not use std::move for returns (buggy version)" >&2
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
