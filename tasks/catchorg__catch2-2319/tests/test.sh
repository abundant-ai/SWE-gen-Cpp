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

# Run the MatchersRanges tests
if ! ctest --test-dir build -R "MatchersRanges" --output-on-failure 2>&1; then
    echo "FAIL: MatchersRanges tests failed"
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
