#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/ExtraTests"
cp "/tests/ExtraTests/CMakeLists.txt" "tests/ExtraTests/CMakeLists.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.approved.txt" "tests/SelfTest/Baselines/compact.sw.approved.txt"
cp "/tests/SelfTest/Baselines/compact.sw.multi.approved.txt" "tests/SelfTest/Baselines/compact.sw.multi.approved.txt"
mkdir -p "tests/TestScripts"
cp "/tests/TestScripts/testConfigureDefaultReporter.py" "tests/TestScripts/testConfigureDefaultReporter.py"

# Reconfigure CMake with testing enabled
# The CMakeLists.txt files configure tests that validate the compact reporter output
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

# Rebuild to incorporate the updated test files
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the RegressionCheck-1670 test which validates compact reporter output
# This test checks for the new "Passed 1 test case with 2 assertions." format
if ! ctest --test-dir build -R "RegressionCheck-1670" --output-on-failure 2>&1; then
    echo "FAIL: RegressionCheck-1670 test failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the DeferredStaticChecks test which validates compact reporter failure output
# This test checks for the new "Failed 1 test case, failed all 3 assertions." format
if ! ctest --test-dir build -R "DeferredStaticChecks" --output-on-failure 2>&1; then
    echo "FAIL: DeferredStaticChecks test failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the Python test script that validates the default reporter configuration
if ! python3 tests/TestScripts/testConfigureDefaultReporter.py . build 2>&1; then
    echo "FAIL: testConfigureDefaultReporter.py test failed"
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
