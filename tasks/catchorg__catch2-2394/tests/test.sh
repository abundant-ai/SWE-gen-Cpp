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
cp "/tests/SelfTest/IntrospectiveTests/TestCaseInfoHasher.tests.cpp" "tests/SelfTest/IntrospectiveTests/TestCaseInfoHasher.tests.cpp"

# Reconfigure CMake after copying test files
if ! cmake -Bbuild -H. -DCMAKE_BUILD_TYPE=Debug -DCATCH_DEVELOPMENT_BUILD=ON -DCATCH_BUILD_TESTING=ON -DCATCH_BUILD_EXTRA_TESTS=ON -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" -G Ninja; then
    echo "CMake configuration failed - test cannot run"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild after copying the updated test files
if ! cmake --build build; then
    echo "Build failed - test cannot run"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the TestCaseInfoHasher tests using the SelfTest executable
# This test validates the test case info hashing functionality
cd build/tests
./SelfTest "TestCaseInfoHasher*" > /tmp/test_output.txt 2>&1
test_status=$?

# Check if tests actually ran and passed
if grep -q "All tests passed" /tmp/test_output.txt; then
    # Tests ran and passed
    echo "TestCaseInfoHasher tests passed successfully"
    test_status=0
elif grep -q "test cases" /tmp/test_output.txt && grep -q "assertions" /tmp/test_output.txt; then
    # Tests ran but some failed
    echo "TestCaseInfoHasher tests ran but some failed"
    cat /tmp/test_output.txt
else
    # Tests didn't run (BASE state - test file doesn't exist or wasn't compiled)
    echo "TestCaseInfoHasher tests not found - test case hashing not implemented"
    cat /tmp/test_output.txt
    test_status=1
fi

cat /tmp/test_output.txt

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
