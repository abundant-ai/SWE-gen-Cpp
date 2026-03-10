#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_mat.cpp" "modules/core/test/test_mat.cpp"

checks_passed=0
checks_failed=0

# PR #12171: Fix cv::merge() and cv::split() hang/crash with non-contiguous matrices
# The fix adds three test cases and corrects the implementation in merge.cpp and split.cpp

# Check 1: Test case for Core_Merge hang_12171 should exist
if grep -q 'TEST(Core_Merge, hang_12171)' modules/core/test/test_mat.cpp 2>/dev/null; then
    echo "PASS: Test case Core_Merge hang_12171 exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test case Core_Merge hang_12171 should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Test case for Core_Split hang_12171 should exist
if grep -q 'TEST(Core_Split, hang_12171)' modules/core/test/test_mat.cpp 2>/dev/null; then
    echo "PASS: Test case Core_Split hang_12171 exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test case Core_Split hang_12171 should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Test case for Core_Split crash_12171 should exist
if grep -q 'TEST(Core_Split, crash_12171)' modules/core/test/test_mat.cpp 2>/dev/null; then
    echo "PASS: Test case Core_Split crash_12171 exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test case Core_Split crash_12171 should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: merge.cpp should have the fixed condition (len > VECSZ*2, not len > VECSZ)
if grep -q 'len > VECSZ\*2' modules/core/src/merge.cpp 2>/dev/null; then
    echo "PASS: merge.cpp has fixed condition (len > VECSZ*2)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: merge.cpp should have fixed condition (len > VECSZ*2)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: split.cpp should have the fixed condition (len > VECSZ*2, not len > VECSZ)
if grep -q 'len > VECSZ\*2' modules/core/src/split.cpp 2>/dev/null; then
    echo "PASS: split.cpp has fixed condition (len > VECSZ*2)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: split.cpp should have fixed condition (len > VECSZ*2)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: split.cpp should use sizeof(T) instead of cn in the offset calculation
if grep -q 'r0 % sizeof(T)' modules/core/src/split.cpp 2>/dev/null; then
    echo "PASS: split.cpp uses sizeof(T) in modulo check"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: split.cpp should use sizeof(T) in modulo check" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: split.cpp should use sizeof(T) for division in offset calculation
if grep -q 'i0 = VECSZ - (r0 / sizeof(T))' modules/core/src/split.cpp 2>/dev/null; then
    echo "PASS: split.cpp uses sizeof(T) for division"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: split.cpp should use sizeof(T) for division" >&2
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
