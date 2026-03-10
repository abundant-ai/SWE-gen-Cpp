#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/video/test/ocl"
cp "/tests/modules/video/test/ocl/test_dis.cpp" "modules/video/test/ocl/test_dis.cpp"

checks_passed=0
checks_failed=0

# Check 1: dis_flow.cpp should have namespace cv opening brace on same line (fixed version)
if grep -q "^namespace cv {$" modules/video/src/dis_flow.cpp; then
    echo "PASS: dis_flow.cpp has namespace cv opening brace on same line (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dis_flow.cpp has namespace cv opening brace on separate line (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dis_flow.cpp should have vector<UMat> u_U with combined x,y components (fixed version)
if grep -q "vector<UMat> u_U; //!< (x,y) component of the flow vectors (CV_32FC2)" modules/video/src/dis_flow.cpp; then
    echo "PASS: dis_flow.cpp has vector<UMat> u_U with combined components (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dis_flow.cpp has separate u_Ux/u_Uy vectors (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dis_flow.cpp should NOT have separate u_Ux vector (fixed version removes it)
if grep -q "vector<UMat> u_Ux;" modules/video/src/dis_flow.cpp; then
    echo "FAIL: dis_flow.cpp still has separate u_Ux vector (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: dis_flow.cpp does not have separate u_Ux vector (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 4: dis_flow.cpp should NOT have separate u_Uy vector (fixed version removes it)
if grep -q "vector<UMat> u_Uy;" modules/video/src/dis_flow.cpp; then
    echo "FAIL: dis_flow.cpp still has separate u_Uy vector (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: dis_flow.cpp does not have separate u_Uy vector (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 5: dis_flow.cpp should have vector<UMat> u_initial_U (fixed version)
if grep -q "vector<UMat> u_initial_U; //!< (x, y) components of the initial flow field" modules/video/src/dis_flow.cpp; then
    echo "PASS: dis_flow.cpp has vector<UMat> u_initial_U (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dis_flow.cpp has separate u_initial_Ux/u_initial_Uy vectors (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: dis_flow.cpp should have UMat u_S with combined components (fixed version)
if grep -q "UMat u_S; //!< intermediate sparse flow representation (x,y components - CV_32FC2)" modules/video/src/dis_flow.cpp; then
    echo "PASS: dis_flow.cpp has UMat u_S with combined components (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dis_flow.cpp has separate u_Sx/u_Sy (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: dis_flow.cpp should NOT have separate u_Sx (fixed version removes it)
if grep -q "UMat u_Sx;" modules/video/src/dis_flow.cpp; then
    echo "FAIL: dis_flow.cpp still has separate u_Sx (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: dis_flow.cpp does not have separate u_Sx (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 8: dis_flow.cpp should have ocl_prepareBuffers with InputArray flow parameter (fixed version)
if grep -q "void ocl_prepareBuffers(UMat &I0, UMat &I1, InputArray flow, bool use_flow);" modules/video/src/dis_flow.cpp; then
    echo "PASS: dis_flow.cpp has ocl_prepareBuffers with InputArray flow (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dis_flow.cpp has ocl_prepareBuffers with UMat &flow (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: dis_flow.cpp should have ocl_Densification with dst_U and src_S parameters (fixed version)
if grep -q "bool ocl_Densification(UMat &dst_U, UMat &src_S, UMat &_I0, UMat &_I1);" modules/video/src/dis_flow.cpp; then
    echo "PASS: dis_flow.cpp has ocl_Densification with dst_U and src_S (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dis_flow.cpp has ocl_Densification with separate dst_Ux/dst_Uy/src_Sx/src_Sy (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: dis_flow.cpp should have ocl_PatchInverseSearch with src_U parameter (fixed version)
if grep -q "bool ocl_PatchInverseSearch(UMat &src_U," modules/video/src/dis_flow.cpp; then
    echo "PASS: dis_flow.cpp has ocl_PatchInverseSearch with src_U (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dis_flow.cpp has ocl_PatchInverseSearch with separate src_Ux/src_Uy (buggy version)" >&2
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
