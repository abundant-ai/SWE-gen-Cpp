#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/Generators.tests.cpp" "tests/SelfTest/UsageTests/Generators.tests.cpp"

# Verify that the fix is applied - check for proper defined() guards
# BUGGY state: #if __cpp_lib_byte > 0
# FIXED state: #if defined(__cpp_lib_byte) && (__cpp_lib_byte > 0)

if ! grep -q 'defined(__cpp_lib_byte)' src/catch2/internal/catch_compiler_capabilities.hpp; then
    echo "FAIL: Missing defined() check for __cpp_lib_byte - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# BUGGY state: #ifdef CATCH_CPP17_OR_GREATER (for conjunction)
# FIXED state: #if defined(__cpp_lib_logical_traits) && __cpp_lib_logical_traits >= 201510

if ! grep -q 'defined.*__cpp_lib_logical_traits.*&&.*__cpp_lib_logical_traits.*>=.*201510' src/catch2/matchers/catch_matchers_templated.hpp; then
    echo "FAIL: Missing proper feature detection for __cpp_lib_logical_traits - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Reconfigure CMake to pick up any changes
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

# Rebuild to pick up changes
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the Generators tests to verify they work correctly
if ! cd build && ctest -R "Generators" --output-on-failure 2>&1; then
    echo "FAIL: Generators tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Fix properly applied - feature detection guards present and tests pass"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
