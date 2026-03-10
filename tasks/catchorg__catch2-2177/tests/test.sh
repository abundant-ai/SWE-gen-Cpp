#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# The PR adds the surrogate build system to tests/CMakeLists.txt.
# We need to verify that it works correctly when enabled.

# Reconfigure CMake with surrogate builds enabled
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_SURROGATES=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator -Wno-error=unused-but-set-variable" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration with CATCH_BUILD_SURROGATES=ON failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Build the surrogate target to verify all headers are self-sufficient
if ! cmake --build build --target Catch2SurrogateTarget 2>&1; then
    echo "FAIL: Building Catch2SurrogateTarget failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Surrogate build system works correctly"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
