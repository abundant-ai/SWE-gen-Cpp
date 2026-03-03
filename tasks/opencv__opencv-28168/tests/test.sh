#!/bin/bash
set -eo pipefail

cd /app/src

# Set test data path environment variable
export OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Apply the fix if Oracle agent (has /solution and /tests mounted)
# NOP agent won't have these mounted, so code and tests remain in buggy state
if [ -f "/solution/fix.patch" ]; then
    echo "Applying source fix from /solution..."

    # Check current state - if code is buggy, apply fix normally; if fixed, skip
    if grep -q "Mat triangleWeights(int length)" modules/photo/src/hdr_common.cpp; then
        echo "Code already has fix (triangleWeights parameter found) - skipping source patch"
    else
        echo "Code is buggy (triangleWeights has no parameter) - applying fix.patch"
        if patch -p1 --batch < /solution/fix.patch 2>&1; then
            echo "Source fix applied successfully"
        else
            echo "FAIL: Could not apply source fix patch"
            echo 0 > /logs/verifier/reward.txt
            exit 1
        fi
    fi

    # Also copy the HEAD test files from /tests
    if [ -d "/tests/modules" ]; then
        echo "Copying test files from /tests..."
        cp -r /tests/modules/* modules/
        echo "Test files copied successfully"
    else
        echo "WARN: No /tests directory found"
    fi
else
    echo "No /solution/fix.patch found - running with buggy code (NOP agent)"
fi

# Reconfigure CMake to pick up any changes
# Use same ASan flags as Dockerfile to detect memory errors
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-g -fsanitize=address -fno-omit-frame-pointer" \
    -DCMAKE_C_FLAGS="-g -fsanitize=address -fno-omit-frame-pointer" \
    -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address" \
    -DCMAKE_MODULE_LINKER_FLAGS="-fsanitize=address" \
    -DCMAKE_SHARED_LINKER_FLAGS="-fsanitize=address" \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_photo=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles
if ! cmake --build build --target opencv_test_photo -j4 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the regression tests for HDR depth consistency
# With the bug, these tests don't exist (were removed by bug.patch)
# With the fix, these tests exist and should pass
test_output=$(./build/bin/opencv_test_photo --gtest_filter="Photo_MergeDebevec.regression_depth_consistency:Photo_MergeRobertson.regression_depth_consistency" 2>&1)
test_exit_code=$?

echo "$test_output"

# Check if the tests actually ran (not just 0 tests)
if echo "$test_output" | grep -q "Running 0 tests"; then
    echo "FAIL: Regression tests don't exist (fix not applied)"
    test_status=1
elif [ $test_exit_code -ne 0 ]; then
    echo "FAIL: HDR depth consistency regression tests failed or crashed"
    test_status=1
else
    echo "SUCCESS: HDR depth consistency regression tests passed"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
