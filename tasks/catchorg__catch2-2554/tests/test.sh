#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/ExtraTests"
cp "/tests/ExtraTests/CMakeLists.txt" "tests/ExtraTests/CMakeLists.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.approved.txt" "tests/SelfTest/Baselines/compact.sw.approved.txt"
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.multi.approved.txt" "tests/SelfTest/Baselines/compact.sw.multi.approved.txt"
mkdir -p "tests/TestScripts"
cp "/tests/TestScripts/testConfigureDefaultReporter.py" "tests/TestScripts/testConfigureDefaultReporter.py"

# Reconfigure CMake to pick up the updated test files
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to pick up changes
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run approval tests - this validates the baseline files (compact.sw.approved.txt, compact.sw.multi.approved.txt)
if ! python3 tools/scripts/approvalTests.py build/tests/SelfTest 2>&1; then
    echo "FAIL: Approval tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the default reporter configuration test
if ! python3 tests/TestScripts/testConfigureDefaultReporter.py . build 2>&1; then
    echo "FAIL: testConfigureDefaultReporter.py failed"
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
