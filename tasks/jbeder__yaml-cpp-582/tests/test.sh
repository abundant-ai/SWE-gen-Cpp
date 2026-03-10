#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/node"
cp "/tests/node/node_test.cpp" "test/node/node_test.cpp"

# Rebuild the test binary with the updated test files
cd build
if ! make -j2 run-tests; then
  echo "ERROR: Failed to build tests with HEAD test files" >&2
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run only tests from NodeTest suite (from node_test.cpp)
./test/run-tests --gtest_filter="NodeTest.*"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
