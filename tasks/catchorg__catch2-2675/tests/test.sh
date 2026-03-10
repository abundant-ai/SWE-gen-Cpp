#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD files from /tests (overwrites BASE state)
# The fix includes changes from two commits:
# 1. Enable aggressive unreachable-code warnings in CMake
mkdir -p "CMake"
cp "/tests/CMake/CatchMiscFunctions.cmake" "CMake/CatchMiscFunctions.cmake"

# 2. Update pragma directive in test file
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/Exception.tests.cpp" "tests/SelfTest/UsageTests/Exception.tests.cpp"

# NOTE: The source file fix (removing unreachable code) comes from fix.patch applied by Oracle agent
# With NOP (no fix.patch), the unreachable code in catch_reporter_registry.cpp will cause build to fail
# With Oracle (fix.patch applied), the unreachable code is removed and build succeeds

# Reconfigure CMake with testing enabled and warnings as errors
# With HEAD files copied, -Wunreachable-code-aggressive is now enabled via CMake
# CATCH_ENABLE_WERROR treats warnings as errors, so unreachable code will fail the build
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=ON \
    -DCATCH_ENABLE_WERROR=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to verify that code compiles with aggressive unreachable-code warnings
# With NOP (buggy code + aggressive warnings), build FAILS due to unreachable-code-return error
# With Oracle (fixed code + aggressive warnings), build succeeds
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed (likely due to unreachable code warning)"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test for Exception handling
# The fix ensures exception tests compile with updated pragma directive for aggressive warnings
if ! ./build/tests/SelfTest '[Exception]' 2>&1; then
    echo "FAIL: Tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: All tests passed"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
