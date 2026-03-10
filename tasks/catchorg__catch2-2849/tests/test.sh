#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/TextFlow.tests.cpp" "tests/SelfTest/IntrospectiveTests/TextFlow.tests.cpp"

# Reconfigure CMake with testing enabled
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the TextFlow tests using the SelfTest binary with tag filters
# Catch2 allows filtering tests by tags - we run tests tagged with [TextFlow]
if ! ./build/tests/SelfTest "[TextFlow]" 2>&1; then
    echo "FAIL: TextFlow tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: TextFlow tests passed"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
