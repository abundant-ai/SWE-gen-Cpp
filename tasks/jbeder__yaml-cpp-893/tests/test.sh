#!/bin/bash

cd /app/src

# The buggy state has a compilation error (missing #include <algorithm> in src/node_data.cpp)
# Apply minimal fix to make the code compile before testing
sed -i '1i #include <algorithm>' src/node_data.cpp

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/integration"
cp "/tests/integration/load_node_test.cpp" "test/integration/load_node_test.cpp"

# Rebuild the test executable with the updated test file
cmake --build build --config Debug 2>&1
rebuild_status=$?

if [ $rebuild_status -ne 0 ]; then
  echo "Rebuild failed with status $rebuild_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $rebuild_status
fi

# Run only the LoadNodeTest tests from load_node_test.cpp
./build/test/yaml-cpp-tests --gtest_filter=LoadNodeTest.*
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
