#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/video/test"
cp "/tests/modules/video/test/test_estimaterigid.cpp" "modules/video/test/test_estimaterigid.cpp"

checks_passed=0
checks_failed=0

# PR #12248: Remove duplicate RANSAC code from video module
# The fix removes the RANSAC implementation from video module and uses calib3d functions instead
# For harbor testing:
# - HEAD (010991a1814102418cb27b319f181665b5b5143c): Fixed version with deprecated estimateRigidTransform using calib3d
# - BASE (after bug.patch): Buggy version with full RANSAC implementation in video module
# - FIXED (after oracle applies fix): Back to fixed version

# Check 1: tracking.hpp should have deprecated estimateRigidTransform (fixed version)
if grep -q 'CV_DEPRECATED CV_EXPORTS Mat estimateRigidTransform( InputArray src, InputArray dst, bool fullAffine );' modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: tracking.hpp has deprecated estimateRigidTransform - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tracking.hpp should have deprecated estimateRigidTransform - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: tracking.hpp SHOULD have deprecation warning (fixed version)
if grep -q '@deprecated Use cv::estimateAffine2D, cv::estimateAffinePartial2D instead' modules/video/include/opencv2/video/tracking.hpp; then
    echo "PASS: tracking.hpp has deprecation warning - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tracking.hpp should have deprecation warning - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: tracking_c.h should NOT have cvEstimateRigidTransform declaration (fixed version)
if ! grep -q 'CVAPI(int)  cvEstimateRigidTransform( const CvArr\* A, const CvArr\* B,' modules/video/include/opencv2/video/tracking_c.h; then
    echo "PASS: tracking_c.h does not have cvEstimateRigidTransform declaration - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tracking_c.h should not have cvEstimateRigidTransform declaration - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: lkpyramid.cpp should NOT have getRTMatrix function (fixed version)
if ! grep -q 'getRTMatrix( const std::vector<Point2f> a, const std::vector<Point2f> b,' modules/video/src/lkpyramid.cpp; then
    echo "PASS: lkpyramid.cpp does not have getRTMatrix function - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lkpyramid.cpp should not have getRTMatrix function - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: lkpyramid.cpp should NOT have RANSAC implementation (fixed version)
if ! grep -q 'int ransacMaxIters, double ransacGoodRatio,' modules/video/src/lkpyramid.cpp && \
   ! grep -q 'RNG rng((uint64)-1);' modules/video/src/lkpyramid.cpp; then
    echo "PASS: lkpyramid.cpp does not have RANSAC implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lkpyramid.cpp should not have RANSAC implementation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: lkpyramid.cpp SHOULD include calib3d.hpp (fixed version)
if grep -q '#include "opencv2/calib3d.hpp"' modules/video/src/lkpyramid.cpp; then
    echo "PASS: lkpyramid.cpp includes calib3d.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: lkpyramid.cpp should include calib3d.hpp - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: compat_video.cpp should NOT have cvEstimateRigidTransform implementation (fixed version)
if ! grep -q 'cvEstimateRigidTransform( const CvArr\* arrA, const CvArr\* arrB, CvMat\* arrM, int full_affine )' modules/video/src/compat_video.cpp; then
    echo "PASS: compat_video.cpp does not have cvEstimateRigidTransform implementation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: compat_video.cpp should not have cvEstimateRigidTransform implementation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: video/CMakeLists.txt SHOULD depend on calib3d (fixed version)
if grep -q 'ocv_define_module(video opencv_imgproc opencv_calib3d WRAP java python js)' modules/video/CMakeLists.txt; then
    echo "PASS: video/CMakeLists.txt depends on calib3d - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: video/CMakeLists.txt should depend on calib3d - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: shape/CMakeLists.txt should depend on calib3d (fixed version)
if grep -q 'ocv_define_module(shape opencv_core opencv_imgproc opencv_calib3d WRAP python)' modules/shape/CMakeLists.txt; then
    echo "PASS: shape/CMakeLists.txt depends on calib3d - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shape/CMakeLists.txt should depend on calib3d - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: shape/precomp.hpp should include calib3d.hpp (fixed version)
if grep -q '#include "opencv2/calib3d.hpp"' modules/shape/src/precomp.hpp; then
    echo "PASS: shape/precomp.hpp includes calib3d.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shape/precomp.hpp should include calib3d.hpp - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: shape/aff_trans.cpp should use estimateAffine2D/estimateAffinePartial2D (fixed version)
if grep -q 'estimateAffine2D(shape1, shape2).convertTo(affine, CV_32F);' modules/shape/src/aff_trans.cpp || \
   grep -q 'estimateAffinePartial2D(shape1, shape2).convertTo(affine, CV_32F);' modules/shape/src/aff_trans.cpp; then
    echo "PASS: shape/aff_trans.cpp uses estimateAffine2D/estimateAffinePartial2D - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: shape/aff_trans.cpp should use estimateAffine2D/estimateAffinePartial2D - buggy version" >&2
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
