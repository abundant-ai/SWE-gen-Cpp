#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/integration"
cp "/tests/integration/load_node_test.cpp" "test/integration/load_node_test.cpp"

# Rebuild the project with the updated test file
cd build
cmake .. -DYAML_CPP_BUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
echo "=== Building yaml-cpp-tests ==="
if ! make yaml-cpp-tests -j2 2>&1; then
    echo "FAIL: Build failed - likely missing methods/classes from the fix"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run only the specific tests that validate the fix (GoogleTest filter)
# These tests are added/modified in the fix and should pass with the fix, fail without it
echo "=== Running load_node_test tests ==="
./test/yaml-cpp-tests --gtest_filter="NodeTest.InfiniteLoopNodes:NodeTest.MultipleDocuments" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
