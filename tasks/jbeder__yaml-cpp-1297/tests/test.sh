#!/bin/bash

cd /app/src

# Set locale to trigger the bug (numbers formatted with locale-specific separators)
export LC_ALL=de_DE.UTF-8
export LANG=de_DE.UTF-8

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/node"
cp "/tests/node/node_test.cpp" "test/node/node_test.cpp"

# Rebuild the project with the updated test file (use C++17 for std::string_view support)
cd build
cmake .. -DYAML_CPP_BUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_STANDARD=17
echo "=== Building yaml-cpp-tests ==="
if ! make yaml-cpp-tests -j2 2>&1; then
    echo "FAIL: Build failed - likely missing methods/classes from the fix"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run only the specific test that validates the fix (GoogleTest filter)
# This test is added in the fix and should pass with the fix, fail without it
echo "=== Running RobustAgainstLocale test ==="
./test/yaml-cpp-tests --gtest_filter="NodeEmitterTest.RobustAgainstLocale" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
