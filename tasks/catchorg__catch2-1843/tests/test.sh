#!/bin/bash

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
cp "/tests/SelfTest/UsageTests/Matchers.tests.cpp" "tests/SelfTest/UsageTests/Matchers.tests.cpp"

# Reconfigure CMake to pick up the updated test file
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild with the updated test file
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the generic and templated matcher tests to verify they pass
if ! ./build/tests/SelfTest "[matchers][generic]" 2>&1; then
    echo "FAIL: Generic matcher tests did not pass"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! ./build/tests/SelfTest "[matchers][templated]" 2>&1; then
    echo "FAIL: Templated matcher tests did not pass"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: All checks passed"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
