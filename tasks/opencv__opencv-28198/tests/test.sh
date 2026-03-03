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
    if grep -q "#pragma warning(push)" modules/gapi/include/opencv2/gapi/util/any.hpp; then
        echo "Code already has fix (pragma warning push found) - skipping source patch"
    else
        echo "Code is buggy (pragma warning push not found) - applying fix.patch"
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
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_gapi=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles
# Use -j1 to avoid OOM during compilation of large test files
if ! cmake --build build --target opencv_test_gapi -j1 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the regression test for async cancellation
# With the bug, this test may fail to compile or behave incorrectly (GCC >= 11 check issue)
# With the fix, this test should compile and pass correctly
set +e  # Temporarily disable exit on error so we can capture the exit code
test_output=$(./build/bin/opencv_test_gapi --gtest_filter="*cancel*basic*" 2>&1)
test_exit_code=$?
set -e

echo "$test_output"

# Check if the test actually ran (not just 0 tests)
if echo "$test_output" | grep -q "Running 0 tests"; then
    echo "FAIL: Async cancellation test doesn't exist or was skipped"
    test_status=1
elif [ $test_exit_code -ne 0 ]; then
    echo "FAIL: Async cancellation test failed or crashed"
    test_status=1
else
    echo "SUCCESS: Async cancellation test passed"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
