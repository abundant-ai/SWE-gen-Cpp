#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_solvepnp_ransac.cpp" "modules/calib3d/test/test_solvepnp_ransac.cpp"

checks_passed=0
checks_failed=0

# Check 1: calib3d.hpp should have solvePnPRefineLM documentation (fixed version)
if grep -q 'CV_EXPORTS_W void solvePnPRefineLM' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has solvePnPRefineLM function declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing solvePnPRefineLM function declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: calib3d.hpp should have solvePnPRefineVVS documentation (fixed version)
if grep -q 'CV_EXPORTS_W void solvePnPRefineVVS' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has solvePnPRefineVVS function declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing solvePnPRefineVVS function declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: solvepnp.cpp should have solvePnPRefineLM implementation (fixed version)
if grep -q 'void solvePnPRefineLM' modules/calib3d/src/solvepnp.cpp; then
    echo "PASS: solvepnp.cpp has solvePnPRefineLM implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: solvepnp.cpp missing solvePnPRefineLM implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: solvepnp.cpp should have solvePnPRefineVVS implementation (fixed version)
if grep -q 'void solvePnPRefineVVS' modules/calib3d/src/solvepnp.cpp; then
    echo "PASS: solvepnp.cpp has solvePnPRefineVVS implementation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: solvepnp.cpp missing solvePnPRefineVVS implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: levmarq.cpp should have the overloaded createLMSolver with eps parameter (fixed version)
if grep -q 'Ptr<LMSolver> createLMSolver(const Ptr<LMSolver::Callback>& cb, int maxIters, double eps)' modules/calib3d/src/levmarq.cpp; then
    echo "PASS: levmarq.cpp has overloaded createLMSolver with eps parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: levmarq.cpp missing overloaded createLMSolver with eps parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: precomp.hpp should declare the overloaded createLMSolver (fixed version)
if grep -q 'CV_EXPORTS Ptr<LMSolver> createLMSolver(const Ptr<LMSolver::Callback>& cb, int maxIters, double eps);' modules/calib3d/src/precomp.hpp; then
    echo "PASS: precomp.hpp declares overloaded createLMSolver (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: precomp.hpp missing overloaded createLMSolver declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_solvepnp_ransac.cpp should have refine tests (fixed version)
if grep -q 'TEST(Calib3d_SolvePnP, refine3pts)' modules/calib3d/test/test_solvepnp_ransac.cpp && \
   grep -q 'TEST(Calib3d_SolvePnP, refine)' modules/calib3d/test/test_solvepnp_ransac.cpp; then
    echo "PASS: test_solvepnp_ransac.cpp has refine tests (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_solvepnp_ransac.cpp missing refine tests (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: opencv.bib should have references for refinement methods (fixed version)
if grep -q '@article{Chaumette06' doc/opencv.bib && \
   grep -q '@misc{Eade13' doc/opencv.bib && \
   grep -q '@misc{Madsen04' doc/opencv.bib && \
   grep -q '@article{Marchand16' doc/opencv.bib; then
    echo "PASS: opencv.bib has required references for refinement methods (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv.bib missing required references for refinement methods (buggy version)" >&2
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
