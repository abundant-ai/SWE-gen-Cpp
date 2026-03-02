#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/automake.sw.approved.txt" "tests/SelfTest/Baselines/automake.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.approved.txt" "tests/SelfTest/Baselines/compact.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/console.std.approved.txt" "tests/SelfTest/Baselines/console.std.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/console.sw.approved.txt" "tests/SelfTest/Baselines/console.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/junit.sw.approved.txt" "tests/SelfTest/Baselines/junit.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/sonarqube.sw.approved.txt" "tests/SelfTest/Baselines/sonarqube.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/tap.sw.approved.txt" "tests/SelfTest/Baselines/tap.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/teamcity.sw.approved.txt" "tests/SelfTest/Baselines/teamcity.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/xml.sw.approved.txt" "tests/SelfTest/Baselines/xml.sw.approved.txt"
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/MatchersRanges.tests.cpp" "tests/SelfTest/UsageTests/MatchersRanges.tests.cpp"

# Verify that the fix is applied - check that quantifiers matchers are present
# BUGGY state: catch_matchers_quantifiers.hpp does NOT exist
# FIXED state: catch_matchers_quantifiers.hpp exists

if [ ! -f "src/catch2/matchers/catch_matchers_quantifiers.hpp" ]; then
    echo "FAIL: Missing catch_matchers_quantifiers.hpp - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that CMakeLists.txt includes the quantifiers header
if ! grep -q 'catch_matchers_quantifiers.hpp' src/CMakeLists.txt; then
    echo "FAIL: CMakeLists.txt missing catch_matchers_quantifiers.hpp - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that the all matchers header includes quantifiers
if ! grep -q 'catch_matchers_quantifiers.hpp' src/catch2/matchers/catch_matchers_all.hpp; then
    echo "FAIL: catch_matchers_all.hpp missing include - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Reconfigure CMake to pick up the changes
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

# Rebuild to verify that code compiles with the quantifiers matchers
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed - likely due to missing quantifiers matchers"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Fix properly applied - quantifiers matchers are present and code compiles"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
