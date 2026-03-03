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
    if grep -q "class CV_EXPORTS RandomNormalLikeLayer" modules/dnn/include/opencv2/dnn/all_layers.hpp; then
        echo "Code already has fix (RandomNormalLikeLayer found) - skipping source patch"
    else
        echo "Code is buggy (RandomNormalLikeLayer missing) - applying fix.patch"
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
    -DBUILD_opencv_dnn=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles
if ! cmake --build build --target opencv_test_dnn -j4 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run a simple test to verify RandomNormalLike layer is available
# The fix adds support for the RandomNormalLike ONNX operator
# With the bug, the layer doesn't exist and parsing ONNX models with it will fail
# With the fix, the layer exists and can be used

# Check if the source file for RandomNormalLike layer exists and was compiled
if [ -f "modules/dnn/src/layers/randomnormallike_layer.cpp" ] && [ -f "modules/dnn/include/opencv2/dnn/all_layers.hpp" ] && grep -q "class CV_EXPORTS RandomNormalLikeLayer" modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "SUCCESS: RandomNormalLikeLayer source and header are present"
    test_status=0
else
    echo "FAIL: RandomNormalLikeLayer source or header not found (fix not applied)"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
