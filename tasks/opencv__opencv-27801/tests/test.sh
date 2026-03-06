#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/3d/test"
cp "/tests/modules/3d/test/test_tsdf.cpp" "modules/3d/test/test_tsdf.cpp"

# Check if InputOutputArray parameters are correctly declared in the fixed version
# In BASE state (buggy), these are changed to InputArray (wrong)
# In HEAD state (fixed), they should be InputOutputArray
checks_passed=0
checks_failed=0

# Check integrateHashTsdfVolumeUnit function signature in hash_tsdf_functions.cpp
if grep -q 'InputOutputArray _volUnitsData, VolumeUnitIndexes& volumeUnits)' modules/3d/src/rgbd/hash_tsdf_functions.cpp; then
    echo "PASS: integrateHashTsdfVolumeUnit uses InputOutputArray for _volUnitsData (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: integrateHashTsdfVolumeUnit does not use InputOutputArray for _volUnitsData (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that getMatRef() is used instead of getMat() for volUnitsData
if grep -q 'Mat& volUnitsData = _volUnitsData.getMatRef();' modules/3d/src/rgbd/hash_tsdf_functions.cpp; then
    echo "PASS: Using getMatRef() to get mutable reference (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Not using getMatRef() for mutable reference (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check ocl_integrateHashTsdfVolumeUnit function signature in hash_tsdf_functions.cpp
if grep -q 'InputOutputArray _volUnitsDataCopy,  InputOutputArray _volUnitsData, CustomHashSet& hashTable' modules/3d/src/rgbd/hash_tsdf_functions.cpp; then
    echo "PASS: ocl_integrateHashTsdfVolumeUnit uses InputOutputArray for data parameters (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ocl_integrateHashTsdfVolumeUnit does not use InputOutputArray (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that getUMatRef() and getMatRef() are used in ocl_integrateHashTsdfVolumeUnit
if grep -q 'UMat& volUnitsData = _volUnitsData.getUMatRef();' modules/3d/src/rgbd/hash_tsdf_functions.cpp; then
    echo "PASS: Using getUMatRef() for volUnitsData (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Not using getUMatRef() for volUnitsData (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

if grep -q 'Mat& volUnitsDataCopy = _volUnitsDataCopy.getMatRef();' modules/3d/src/rgbd/hash_tsdf_functions.cpp; then
    echo "PASS: Using getMatRef() for volUnitsDataCopy (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Not using getMatRef() for volUnitsDataCopy (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check function declarations in hash_tsdf_functions.hpp
if grep -q 'InputOutputArray _volUnitsData, VolumeUnitIndexes& volumeUnits);' modules/3d/src/rgbd/hash_tsdf_functions.hpp; then
    echo "PASS: Header declares integrateHashTsdfVolumeUnit with InputOutputArray (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Header does not declare InputOutputArray correctly (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

if grep -q 'InputOutputArray _volUnitsDataCopy, InputOutputArray _volUnitsData, CustomHashSet& hashTable' modules/3d/src/rgbd/hash_tsdf_functions.hpp; then
    echo "PASS: Header declares ocl_integrateHashTsdfVolumeUnit with InputOutputArray (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Header does not declare ocl function correctly (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that test file has the removed test code restored (parallel_for_ lambda parameters fixed)
if grep -q 'parallel_for_(range, \[&\](const Range& rows)' modules/3d/test/test_tsdf.cpp; then
    echo "PASS: Test file has correct lambda parameter (rows) in renderPointsNormals (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test file does not have correct lambda parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check that hugeSceneGrowthTest and CubesScene are present in the test file
if grep -q 'void hugeSceneGrowthTest()' modules/3d/test/test_tsdf.cpp; then
    echo "PASS: hugeSceneGrowthTest function is present (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: hugeSceneGrowthTest function is missing (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

if grep -q 'struct CubesScene : Scene' modules/3d/test/test_tsdf.cpp; then
    echo "PASS: CubesScene struct is present (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CubesScene struct is missing (buggy version)" >&2
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
