#!/bin/bash

cd /app/src

checks_passed=0
checks_failed=0

# Check 1: ippe.cpp should exist (new file in fixed version)
if [ -f "modules/calib3d/src/ippe.cpp" ]; then
    echo "PASS: ippe.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ippe.cpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: ippe.hpp should exist (new file in fixed version)
if [ -f "modules/calib3d/src/ippe.hpp" ]; then
    echo "PASS: ippe.hpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ippe.hpp missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: SolvePnPMethod enum should exist (fixed version uses proper enum)
if grep -q 'enum SolvePnPMethod' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has SolvePnPMethod enum (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing SolvePnPMethod enum (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: SOLVEPNP_IPPE constant should exist (fixed version)
if grep -q 'SOLVEPNP_IPPE' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has SOLVEPNP_IPPE constant (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing SOLVEPNP_IPPE constant (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: SOLVEPNP_IPPE_SQUARE constant should exist (fixed version)
if grep -q 'SOLVEPNP_IPPE_SQUARE' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has SOLVEPNP_IPPE_SQUARE constant (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing SOLVEPNP_IPPE_SQUARE constant (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Collins14 citation should be present in opencv.bib (fixed version)
if grep -q '@article{Collins14' doc/opencv.bib; then
    echo "PASS: opencv.bib has Collins14 citation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv.bib missing Collins14 citation (buggy version)" >&2
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
