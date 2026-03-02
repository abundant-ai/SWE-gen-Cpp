#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/Benchmark.tests.cpp" "tests/SelfTest/UsageTests/Benchmark.tests.cpp"

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

# Run the specific test that validates --skip-benchmarks functionality
# This test should pass with the fix (test case exists and --skip-benchmarks works)
# but fail without the fix (test case or flag doesn't exist)
if ! ./build/tests/SelfTest "Skip benchmark macros" --reporter console --skip-benchmarks 2>&1 | tee /tmp/test_output.txt; then
    echo "FAIL: Test execution failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify the test passed with expected output
if ! grep -q "All tests passed (2 assertions in 1 test case)" /tmp/test_output.txt; then
    echo "FAIL: Test did not pass with expected output"
    cat /tmp/test_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that benchmark output was skipped (shouldn't see "benchmark name" in output)
if grep -q "benchmark name" /tmp/test_output.txt; then
    echo "FAIL: Benchmarks were not skipped"
    cat /tmp/test_output.txt
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
