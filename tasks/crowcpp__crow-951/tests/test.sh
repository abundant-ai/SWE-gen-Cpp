#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Check that the test file has the #ifdef blocks (feature exists in HEAD, not in BASE)
if ! grep -q "#ifdef CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST" tests/unittest.cpp; then
    echo "FAIL: unittest.cpp doesn't have #ifdef blocks for CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST"
    echo "This indicates the feature has not been implemented."
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Check that CMakeLists.txt has the option defined
if ! grep -q "CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST" CMakeLists.txt; then
    echo "FAIL: CMakeLists.txt doesn't define CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST option"
    echo "This indicates the feature has not been implemented."
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Test 1: Build and run with CMake option OFF (should return 204)
echo "TEST 1: Building with CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST=OFF"
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_ENABLE_SSL=ON \
    -DCROW_ENABLE_COMPRESSION=ON \
    -DCROW_ENABLE_SANITIZERS=ON \
    -DCROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST=OFF \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration with option OFF failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! cmake --build build --target unittest 2>&1; then
    echo "FAIL: Build with option OFF failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! ./build/tests/unittest "http_method" 2>&1; then
    echo "FAIL: Tests with option OFF failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Test 2: Build and run with CMake option ON (should return 200)
echo "TEST 2: Building with CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST=ON"
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_ENABLE_SSL=ON \
    -DCROW_ENABLE_COMPRESSION=ON \
    -DCROW_ENABLE_SANITIZERS=ON \
    -DCROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST=ON \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration with option ON failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! cmake --build build --target unittest 2>&1; then
    echo "FAIL: Build with option ON failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! ./build/tests/unittest "http_method" 2>&1; then
    echo "FAIL: Tests with option ON failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Feature implemented correctly - tests pass with both option settings"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
