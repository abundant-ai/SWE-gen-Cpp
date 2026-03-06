#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib/test"
cp "/tests/modules/calib/test/test_multiview_calib.cpp" "modules/calib/test/test_multiview_calib.cpp"

# Check if TermCriteria parameter is correctly added back in the fixed version
# In BASE state (buggy), TermCriteria parameter is removed from function signatures
# In HEAD state (fixed), TermCriteria parameter should be present
checks_passed=0
checks_failed=0

# Check header file for TermCriteria in calibrateMultiview function declarations
if grep -q 'TermCriteria criteria = TermCriteria(TermCriteria::COUNT + TermCriteria::EPS, 100, DBL_EPSILON));' modules/calib/include/opencv2/calib.hpp; then
    echo "PASS: calibrateMultiview header has TermCriteria parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibrateMultiview header missing TermCriteria parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check if the documentation comment for criteria is present
if grep -q '@param\[in\] criteria Termination criteria for the iterative optimization algorithm.' modules/calib/include/opencv2/calib.hpp; then
    echo "PASS: Documentation for criteria parameter is present (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Documentation for criteria parameter is missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check multiview_calibration.cpp for TermCriteria parameter in function signatures
if grep -q 'Mat &intrinsic_flags, int extrinsic_flags, TermCriteria criteria)' modules/calib/src/multiview_calibration.cpp; then
    echo "PASS: pairwiseRegistration has TermCriteria parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pairwiseRegistration missing TermCriteria parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that registerCameras call includes criteria parameter
if grep -q 'extrinsic_flags, criteria);' modules/calib/src/multiview_calibration.cpp; then
    echo "PASS: registerCameras call includes criteria parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: registerCameras call missing criteria parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that stereoCalibrate calls include criteria parameter
if grep -q 'extrinsic_flags, criteria);' modules/calib/src/multiview_calibration.cpp && \
   grep -q 'extrinsic_flags, criteria);' modules/calib/src/multiview_calibration.cpp; then
    echo "PASS: stereoCalibrate calls include criteria parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: stereoCalibrate calls missing criteria parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that pairwise functions are called with criteria parameter
if grep -q 'flagsForIntrinsics_mat, 0, criteria);' modules/calib/src/multiview_calibration.cpp; then
    echo "PASS: Pairwise functions called with criteria parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Pairwise functions not called with criteria parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that criteria is passed to optimizeLM (not termCrit local variable)
if grep -q 'multiview::optimizeLM(param, robust_fnc, criteria, valid_frames' modules/calib/src/multiview_calibration.cpp; then
    echo "PASS: optimizeLM uses criteria parameter from function signature (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: optimizeLM not using criteria parameter from function signature (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that local termCrit variable is removed
if ! grep -q 'TermCriteria termCrit (TermCriteria::COUNT+TermCriteria::EPS, 100, 1e-6);' modules/calib/src/multiview_calibration.cpp; then
    echo "PASS: Local termCrit variable is removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Local termCrit variable still present (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check test file changes from ASSERT to EXPECT
if grep -q 'EXPECT_EQ(cam_names.size(), image_points_all.size());' modules/calib/test/test_multiview_calib.cpp; then
    echo "PASS: Test file uses EXPECT_EQ instead of ASSERT_EQ (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test file still uses ASSERT_EQ (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that EXPECT_TRUE is used instead of ASSERT_TRUE in RegisterCamerasTest
if grep -q 'EXPECT_TRUE(!image_points_all\[i\].empty());' modules/calib/test/test_multiview_calib.cpp; then
    echo "PASS: RegisterCamerasTest uses EXPECT_TRUE (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: RegisterCamerasTest uses ASSERT_TRUE (buggy version)" >&2
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
