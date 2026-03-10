#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/Generators.tests.cpp" "tests/SelfTest/UsageTests/Generators.tests.cpp"

# The bug is compatibility-related: the buggy source code (lacking proper feature detection)
# combined with simplified test syntax will fail to compile on older toolchains.
# On modern compilers, both versions work, so we verify the fix by checking if the
# compatibility guards are present in the source files.

# Check if the compatibility fixes are present in catch_compiler_capabilities.hpp
if ! grep -q "defined(__cpp_lib_byte) && (__cpp_lib_byte > 0)" src/catch2/internal/catch_compiler_capabilities.hpp; then
    echo "FAIL: Missing compatibility fix for __cpp_lib_byte in catch_compiler_capabilities.hpp"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Check if the compatibility fixes are present in catch_matchers_templated.hpp
if ! grep -q "defined( __cpp_lib_logical_traits ) && __cpp_lib_logical_traits >= 201510" src/catch2/matchers/catch_matchers_templated.hpp; then
    echo "FAIL: Missing compatibility fix for __cpp_lib_logical_traits in catch_matchers_templated.hpp"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Reconfigure CMake with testing enabled
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator -Wno-error=unused-but-set-variable" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to incorporate the updated test files
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific tests that use the generator table functionality
if ! ./build/tests/SelfTest "strlen2" --reporter console --success 2>&1; then
    echo "FAIL: strlen2 test failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! ./build/tests/SelfTest "Eating cucumbers" --reporter console --success 2>&1; then
    echo "FAIL: Eating cucumbers test failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: All tests passed and compatibility fixes are present"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
