#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.approved.txt" "tests/SelfTest/Baselines/compact.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/console.sw.approved.txt" "tests/SelfTest/Baselines/console.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/tap.sw.approved.txt" "tests/SelfTest/Baselines/tap.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/xml.sw.approved.txt" "tests/SelfTest/Baselines/xml.sw.approved.txt"
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/String.tests.cpp" "tests/SelfTest/IntrospectiveTests/String.tests.cpp"
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/Xml.tests.cpp" "tests/SelfTest/IntrospectiveTests/Xml.tests.cpp"

# Verify that the fix is applied - check that -Wold-style-cast is enabled
# BUGGY state: -Wold-style-cast is NOT present in CMake/MiscFunctions.cmake
# FIXED state: -Wold-style-cast is present in CMake/MiscFunctions.cmake
if ! grep -q '"-Wold-style-cast"' CMake/MiscFunctions.cmake; then
    echo "FAIL: Missing -Wold-style-cast flag - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that static_cast is used instead of C-style casts
if grep -q '(int)(-2\. \* k0' src/catch2/benchmark/detail/catch_stats.cpp; then
    echo "FAIL: C-style cast (int) still present in catch_stats.cpp - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if grep -q '(double)n' src/catch2/benchmark/detail/catch_stats.hpp; then
    echo "FAIL: C-style cast (double) still present in catch_stats.hpp - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Reconfigure CMake to pick up the changes with -Wold-style-cast enabled
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

# Rebuild to verify that code compiles with -Wold-style-cast enabled
# This will fail if there are any C-style casts remaining
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed - likely due to old-style cast warnings"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Fix properly applied - code compiles with -Wold-style-cast enabled"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
