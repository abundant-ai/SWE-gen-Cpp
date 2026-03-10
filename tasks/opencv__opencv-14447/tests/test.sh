#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_cameracalibration.cpp" "modules/calib3d/test/test_cameracalibration.cpp"
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_solvepnp_ransac.cpp" "modules/calib3d/test/test_solvepnp_ransac.cpp"
mkdir -p "modules/calib3d/test"
cp "/tests/modules/calib3d/test/test_undistort.cpp" "modules/calib3d/test/test_undistort.cpp"

checks_passed=0
checks_failed=0

# Check 1: calib3d.hpp should have updated imagePoints documentation (fixed version)
if grep -q '2xN/Nx2 1-channel or 1xN/Nx1 2-channel' modules/calib3d/include/opencv2/calib3d.hpp; then
    echo "PASS: calib3d.hpp has updated imagePoints documentation (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calib3d.hpp missing updated imagePoints documentation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: calibration.cpp should have DLT check for 6 points (fixed version)
if grep -q 'CV_CheckGE(count, 6, "DLT algorithm needs at least 6 points' modules/calib3d/src/calibration.cpp; then
    echo "PASS: calibration.cpp has DLT 6-point check (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibration.cpp missing DLT 6-point check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: calibration.cpp projectPoints should have transpose logic (fixed version)
if grep -q 'if (npoints < 0)' modules/calib3d/src/calibration.cpp && \
   grep -q 'opoints = opoints.t();' modules/calib3d/src/calibration.cpp; then
    echo "PASS: calibration.cpp projectPoints has transpose logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibration.cpp projectPoints missing transpose logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: calibration.cpp projectPoints should have reshape logic (fixed version)
if grep -A 4 'npoints = opoints.checkVector(3);' modules/calib3d/src/calibration.cpp | grep -q 'if (opoints.cols == 3)'; then
    echo "PASS: calibration.cpp projectPoints has reshape logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: calibration.cpp projectPoints missing reshape logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: solvepnp.cpp solvePnPRansac should have reshape logic (fixed version)
if grep -A 3 'if( model_points == npoints )' modules/calib3d/src/solvepnp.cpp | grep -q 'opoints = opoints.reshape(3);' && \
   grep -A 4 'if( model_points == npoints )' modules/calib3d/src/solvepnp.cpp | grep -q 'ipoints = ipoints.reshape(2);'; then
    echo "PASS: solvepnp.cpp solvePnPRansac has reshape logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: solvepnp.cpp solvePnPRansac missing reshape logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: solvepnp.cpp solveP3P should have reshape logic (fixed version)
if grep -A 5 'CV_Assert( npoints == 3 || npoints == 4 );' modules/calib3d/src/solvepnp.cpp | grep -q 'if (opoints.cols == 3)' && \
   grep -A 7 'CV_Assert( npoints == 3 || npoints == 4 );' modules/calib3d/src/solvepnp.cpp | grep -q 'if (ipoints.cols == 2)'; then
    echo "PASS: solvepnp.cpp solveP3P has reshape logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: solvepnp.cpp solveP3P missing reshape logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: solvepnp.cpp solvePnPGeneric should have reshape logic (fixed version)
if grep -A 15 'int solvePnPGeneric' modules/calib3d/src/solvepnp.cpp | grep -q 'if (opoints.cols == 3)' && \
   grep -A 17 'int solvePnPGeneric' modules/calib3d/src/solvepnp.cpp | grep -q 'if (ipoints.cols == 2)'; then
    echo "PASS: solvepnp.cpp solvePnPGeneric has reshape logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: solvepnp.cpp solvePnPGeneric missing reshape logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: perf_pnp.cpp should test with 6 points (fixed version)
if grep -q 'testing::Values(6, 3\*9, 7\*13)' modules/calib3d/perf/perf_pnp.cpp; then
    echo "PASS: perf_pnp.cpp tests with 6 points (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_pnp.cpp not testing with 6 points (buggy version)" >&2
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
