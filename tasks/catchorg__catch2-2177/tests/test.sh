#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Verify that the fix is applied - check for CATCH_BUILD_SURROGATES option
# BUGGY state: CATCH_BUILD_SURROGATES option is NOT present
# FIXED state: CATCH_BUILD_SURROGATES option is present

if ! grep -q 'CATCH_BUILD_SURROGATES' CMakeLists.txt; then
    echo "FAIL: Missing CATCH_BUILD_SURROGATES option - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that the surrogate TU logic is in tests/CMakeLists.txt
if ! grep -q 'CATCH_BUILD_SURROGATES' tests/CMakeLists.txt; then
    echo "FAIL: Missing CATCH_BUILD_SURROGATES logic in tests/CMakeLists.txt - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Reconfigure CMake to pick up any changes, with CATCH_BUILD_SURROGATES enabled
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=ON \
    -DCATCH_BUILD_SURROGATES=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration with CATCH_BUILD_SURROGATES failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to pick up changes and build surrogate TUs
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that the Catch2SurrogateTarget was created
if ! cmake --build build --target Catch2SurrogateTarget 2>&1; then
    echo "FAIL: Catch2SurrogateTarget build failed - surrogate TUs not working"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Fix properly applied - CATCH_BUILD_SURROGATES option present and surrogate TUs build"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
