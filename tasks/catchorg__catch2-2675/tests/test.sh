#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/Exception.tests.cpp" "tests/SelfTest/UsageTests/Exception.tests.cpp"

# The fix must make the code compile with -Wunreachable-code-aggressive
# Reconfigure with aggressive unreachable code checking
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator -Wunreachable-code-aggressive" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild - in buggy state this will fail due to unreachable code
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed with -Wunreachable-code-aggressive"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the exception tests to verify they still work correctly
if ! ./build/tests/SelfTest "[exception]" 2>&1; then
    echo "FAIL: Exception tests did not pass"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: All checks passed"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
