#!/bin/bash
set -eo pipefail

cd /app/src

# Set test data path environment variable
export OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_webp.cpp" "modules/imgcodecs/test/test_webp.cpp"

# Reconfigure CMake to pick up the updated test files
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_imgcodecs=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles with the fix
if ! cmake --build build --target opencv_test_imgcodecs -j2 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run WebP tests to verify the fix
if ! ./build/bin/opencv_test_imgcodecs --gtest_filter="*Imgcodecs_WebP*" 2>&1; then
    echo "FAIL: Tests failed"
    test_status=1
else
    echo "SUCCESS: All tests passed"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
