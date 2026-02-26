#!/bin/bash

cd /app/src

# Re-enable warning flags if they're not already present (in case agent didn't add them)
# Disable unrelated literal-operator warnings that aren't part of this PR
if ! grep -q "Wdeprecated" CMakeLists.txt; then
  sed -i 's/-Wno-sign-conversion)/-Wno-sign-conversion -Wdeprecated -Wno-deprecated-literal-operator -Wweak-vtables)/' CMakeLists.txt
elif ! grep -q "Wno-deprecated-literal-operator" CMakeLists.txt; then
  # If -Wdeprecated is already added (by oracle), just add the exception
  sed -i 's/-Wdeprecated/-Wdeprecated -Wno-deprecated-literal-operator/' CMakeLists.txt
fi

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/core-test.cc" "test/core-test.cc"
mkdir -p "test"
cp "/tests/test-assert.h" "test/test-assert.h"

# Reconfigure with the updated test files (enable PEDANTIC to catch warnings, WERROR to treat warnings as errors)
# Use C++11 to match the original PR environment
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=11 \
    -DFMT_TEST=ON \
    -DFMT_PEDANTIC=ON \
    -DFMT_WERROR=ON 2>&1

# Build the specific test target (capture both stdout and stderr)
cmake --build build --target core-test --parallel $(nproc) 2>&1
build_status=$?

# If build failed, exit with error
if [ $build_status -ne 0 ]; then
  echo "Build failed with status $build_status"
  test_status=1
else
  # Run the test
  ./build/bin/core-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
