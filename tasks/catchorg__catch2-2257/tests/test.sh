#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/ExtraTests"
cp "/tests/ExtraTests/CMakeLists.txt" "tests/ExtraTests/CMakeLists.txt"
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
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/CmdLine.tests.cpp" "tests/SelfTest/IntrospectiveTests/CmdLine.tests.cpp"
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/Sharding.tests.cpp" "tests/SelfTest/IntrospectiveTests/Sharding.tests.cpp"
mkdir -p "tests/TestScripts"
cp "/tests/TestScripts/testSharding.py" "tests/TestScripts/testSharding.py"

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

# Run the SelfTest executable directly to test Sharding and CmdLine
if ! ./build/tests/SelfTest "Sharding" --reporter console --success 2>&1; then
    echo "FAIL: Sharding tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! ./build/tests/SelfTest "[sharding]" --reporter console --success 2>&1; then
    echo "FAIL: [sharding] tag tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the Python test script for sharding with the SelfTest executable path
if ! python3 tests/TestScripts/testSharding.py ./build/tests/SelfTest 2>&1; then
    echo "FAIL: Python sharding test script failed"
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
