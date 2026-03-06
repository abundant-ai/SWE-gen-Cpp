#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_mat.cpp" "modules/core/test/test_mat.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_umat.cpp" "modules/core/test/test_umat.cpp"

# Reconfigure cmake to pick up the new test files, then rebuild
# Use -j2 to balance speed and memory usage
# Need to rebuild both the core module and the tests to pick up code changes
cd build
cmake -GNinja \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_DOCS=OFF \
    ..
ninja -j2 opencv_core opencv_test_core

# Run only the copyToConvertTo_Empty tests (the tests added in this PR)
# Using gtest_filter to run only tests with "copyToConvertTo_Empty" in their name
# Capture output to verify tests actually ran
output=$(./bin/opencv_test_core --gtest_filter=*copyToConvertTo_Empty* 2>&1)
test_status=$?
echo "$output"

# Check if any tests actually ran (gtest reports "Running N tests" where N > 0)
# If 0 tests ran, the test file doesn't exist (buggy state) - should fail
if echo "$output" | grep -q "Running 0 tests"; then
    echo "ERROR: No tests found matching filter. Test file may not exist." >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
