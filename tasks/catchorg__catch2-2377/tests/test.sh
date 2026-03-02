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

# Rebuild to pick up changes (including the MatchersRanges test)
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific tests for RangeEquals and UnorderedRangeEquals
# These tests are in tests/SelfTest/UsageTests/MatchersRanges.tests.cpp
if ! ./build/tests/SelfTest "Usage of RangeEquals range matcher" 2>&1 | tee /tmp/test_output.txt; then
    echo "FAIL: RangeEquals test failed"
    cat /tmp/test_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! ./build/tests/SelfTest "Usage of UnorderedRangeEquals range matcher" 2>&1 | tee -a /tmp/test_output.txt; then
    echo "FAIL: UnorderedRangeEquals test failed"
    cat /tmp/test_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! ./build/tests/SelfTest "Type conversions of RangeEquals and similar" 2>&1 | tee -a /tmp/test_output.txt; then
    echo "FAIL: Type conversions of RangeEquals test failed"
    cat /tmp/test_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: All RangeEquals tests passed"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
