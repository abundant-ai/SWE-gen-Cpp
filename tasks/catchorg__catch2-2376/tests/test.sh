#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/Misc.tests.cpp" "tests/SelfTest/UsageTests/Misc.tests.cpp"

# Reconfigure CMake to pick up the updated test files
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

# Rebuild to pick up changes (including the new test case and noexcept changes)
# The fix makes disengage_platform() and disengage() noexcept
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that the fix has been applied by checking for noexcept in the source files
# The fix makes disengage_platform() noexcept in the header and implementation
if ! grep -q "void disengage_platform() noexcept" src/catch2/internal/catch_fatal_condition_handler.hpp; then
    echo "FAIL: disengage_platform() is not noexcept in header file"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! grep -q "void disengage() noexcept" src/catch2/internal/catch_fatal_condition_handler.hpp; then
    echo "FAIL: disengage() is not noexcept in header file"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Check that disengage_platform() is noexcept in the implementation file
if ! grep -q "void FatalConditionHandler::disengage_platform() noexcept" src/catch2/internal/catch_fatal_condition_handler.cpp; then
    echo "FAIL: FatalConditionHandler::disengage_platform() is not noexcept in implementation"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Build succeeded and noexcept qualifiers are present"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
