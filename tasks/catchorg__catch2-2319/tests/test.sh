#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/automake.sw.approved.txt" "tests/SelfTest/Baselines/automake.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/automake.sw.multi.approved.txt" "tests/SelfTest/Baselines/automake.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.approved.txt" "tests/SelfTest/Baselines/compact.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.multi.approved.txt" "tests/SelfTest/Baselines/compact.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/console.std.approved.txt" "tests/SelfTest/Baselines/console.std.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/console.sw.approved.txt" "tests/SelfTest/Baselines/console.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/console.sw.multi.approved.txt" "tests/SelfTest/Baselines/console.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/junit.sw.approved.txt" "tests/SelfTest/Baselines/junit.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/junit.sw.multi.approved.txt" "tests/SelfTest/Baselines/junit.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/sonarqube.sw.approved.txt" "tests/SelfTest/Baselines/sonarqube.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/sonarqube.sw.multi.approved.txt" "tests/SelfTest/Baselines/sonarqube.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/tap.sw.approved.txt" "tests/SelfTest/Baselines/tap.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/tap.sw.multi.approved.txt" "tests/SelfTest/Baselines/tap.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/teamcity.sw.approved.txt" "tests/SelfTest/Baselines/teamcity.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/teamcity.sw.multi.approved.txt" "tests/SelfTest/Baselines/teamcity.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/xml.sw.approved.txt" "tests/SelfTest/Baselines/xml.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/xml.sw.multi.approved.txt" "tests/SelfTest/Baselines/xml.sw.multi.approved.txt"
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/MatchersRanges.tests.cpp" "tests/SelfTest/UsageTests/MatchersRanges.tests.cpp"

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

# Rebuild to pick up changes (including the new matchers and updated test cases)
# The fix adds AllTrue(), NoneTrue(), and AnyTrue() matchers
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that the fix has been applied by checking for the new matcher functions
# The fix adds AllTrueMatcher, NoneTrueMatcher, and AnyTrueMatcher classes
if ! grep -q "class AllTrueMatcher" src/catch2/matchers/catch_matchers_quantifiers.hpp; then
    echo "FAIL: AllTrueMatcher class not found in header file"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! grep -q "class NoneTrueMatcher" src/catch2/matchers/catch_matchers_quantifiers.hpp; then
    echo "FAIL: NoneTrueMatcher class not found in header file"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! grep -q "class AnyTrueMatcher" src/catch2/matchers/catch_matchers_quantifiers.hpp; then
    echo "FAIL: AnyTrueMatcher class not found in header file"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Check that the new implementation file exists
if [ ! -f src/catch2/matchers/catch_matchers_quantifiers.cpp ]; then
    echo "FAIL: catch_matchers_quantifiers.cpp implementation file not found"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Build succeeded and new matchers are present"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
