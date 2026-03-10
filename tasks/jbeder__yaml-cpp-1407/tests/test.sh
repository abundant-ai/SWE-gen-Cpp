#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/integration"
cp "/tests/integration/emitter_test.cpp" "test/integration/emitter_test.cpp"

# Rebuild the project with the updated test file
cd build
cmake .. -DYAML_CPP_BUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
echo "=== Building yaml-cpp-tests ==="
if ! make yaml-cpp-tests -j2 2>&1; then
    echo "FAIL: Build failed - likely missing methods/classes from the fix"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run only the specific test that validates the fix (GoogleTest filter)
echo "=== Running ShowTrailingZero test ==="
./test/yaml-cpp-tests --gtest_filter=EmitterTest.ShowTrailingZero 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
