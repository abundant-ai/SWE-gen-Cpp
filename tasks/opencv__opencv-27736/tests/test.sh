#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_solvepnp_ransac.cpp" "modules/calib3d/test/test_solvepnp_ransac.cpp"

checks_passed=0
checks_failed=0

# Check 1: calib3d.bib should reference ding2023revisiting (fixed version)
if grep -q '@inproceedings{ding2023revisiting,' modules/calib3d/doc/calib3d.bib && \
   grep -q 'title={Revisiting the P3P Problem}' modules/calib3d/doc/calib3d.bib && \
   grep -q 'author={Ding, Yaqing' modules/calib3d/doc/calib3d.bib; then
    echo "PASS: calib3d.bib has ding2023revisiting citation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.bib missing ding2023revisiting citation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: solvePnP.markdown should reference ding2023revisiting
if grep -q 'cv::SOLVEPNP_P3P Method is based on the paper of Ding' modules/calib3d/doc/solvePnP.markdown && \
   grep -q 'Revisiting the P3P Problem.*@cite ding2023revisiting' modules/calib3d/doc/solvePnP.markdown; then
    echo "PASS: solvePnP.markdown references ding2023revisiting (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: solvePnP.markdown doesn't reference ding2023revisiting (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: calib3d.hpp should reference ding2023revisiting
if grep -q 'SOLVEPNP_P3P.*Revisiting the P3P Problem @cite ding2023revisiting' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp references ding2023revisiting (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp doesn't reference ding2023revisiting (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: p3p.cpp should use modern implementation from PoseLib
if grep -q 'https://github.com/PoseLib/PoseLib' modules/calib3d/src/p3p.cpp && \
   grep -q 'solve_cubic_single_real' modules/calib3d/src/p3p.cpp; then
    echo "PASS: p3p.cpp uses modern PoseLib-based implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: p3p.cpp missing modern implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: p3p.h should have default constructor and estimate method
if grep -q 'p3p();' modules/calib3d/src/p3p.h && \
   grep -q 'int estimate' modules/calib3d/src/p3p.h; then
    echo "PASS: p3p.h has modern API (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: p3p.h missing modern API (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: solvepnp.cpp should use estimate method
if grep -q 'p3p P3Psolver;' modules/calib3d/src/solvepnp.cpp && \
   grep -q 'P3Psolver.estimate' modules/calib3d/src/solvepnp.cpp; then
    echo "PASS: solvepnp.cpp uses estimate method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: solvepnp.cpp doesn't use estimate method (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_solvepnp_ransac.cpp should have appropriate epsilon for P3P
if grep -q 'eps\[SOLVEPNP_P3P\] = 1.0e-4;' modules/calib3d/test/test_solvepnp_ransac.cpp; then
    echo "PASS: test_solvepnp_ransac.cpp has appropriate P3P epsilon (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_solvepnp_ransac.cpp missing P3P epsilon (buggy version)" >&2
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
