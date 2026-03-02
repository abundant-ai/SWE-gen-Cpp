#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
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
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/Json.tests.cpp" "tests/SelfTest/IntrospectiveTests/Json.tests.cpp"
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/Reporters.tests.cpp" "tests/SelfTest/IntrospectiveTests/Reporters.tests.cpp"

# Reconfigure CMake to pick up the updated test files
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

# Rebuild with the updated test files
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the Json tests to verify they pass
if ! ./build/tests/SelfTest "[JsonWriter]" 2>&1; then
    echo "FAIL: JsonWriter tests did not pass"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the reporter tests to verify JSON reporter works
if ! ./build/tests/SelfTest "[reporters]" 2>&1; then
    echo "FAIL: Reporter tests did not pass"
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
