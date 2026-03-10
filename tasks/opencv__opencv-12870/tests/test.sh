#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_basic_hetero_tests.cpp" "modules/gapi/test/gapi_basic_hetero_tests.cpp"

checks_passed=0
checks_failed=0

# PR #12870: Add validation for multi-island graphs with GFluidOutputRois
# For harbor testing:
# - HEAD (bb905f7ae6a665c32663784b8ed5d1184229ed1a): Fixed version with multi-island validation
# - BASE (after bug.patch): Buggy version without multi-island validation
# - FIXED (after fix.patch): Back to fixed version

# Check 1: gfluidbackend.cpp should have num_islands calculation in fixed version
if grep -q 'const auto num_islands = std::count_if' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: gfluidbackend.cpp has num_islands calculation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbackend.cpp missing num_islands calculation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gfluidbackend.cpp should have multi-island check with error message
if grep -q 'if (num_islands > 1 && out_rois.has_value())' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: gfluidbackend.cpp has multi-island check - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbackend.cpp missing multi-island check - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gfluidbackend.cpp should have error message for multi-island with output ROIs
if grep -q 'GFluidOutputRois feature supports only one-island graphs' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: gfluidbackend.cpp has one-island error message - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbackend.cpp missing one-island error message - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: gfluidbackend.cpp should have GIslandModel::Graph usage for island counting
if grep -q 'GIslandModel::Graph gim' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: gfluidbackend.cpp has GIslandModel::Graph for island counting - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbackend.cpp missing GIslandModel::Graph - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gfluidbackend.cpp should use std::move for rois in fixed version
if grep -q 'std::move(rois.rois)' modules/gapi/src/backends/fluid/gfluidbackend.cpp; then
    echo "PASS: gfluidbackend.cpp uses std::move for rois - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbackend.cpp not using std::move for rois - buggy version" >&2
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
