#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/TextFlow.tests.cpp" "tests/SelfTest/IntrospectiveTests/TextFlow.tests.cpp"

# Reconfigure CMake to pick up the updated test file
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild with the updated test file
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the TextFlow tests to verify they pass
if ! ./build/tests/SelfTest "[TextFlow]" 2>&1; then
    echo "FAIL: TextFlow tests did not pass"
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
