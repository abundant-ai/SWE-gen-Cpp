#!/bin/bash

cd /app/src

# Fix compilation issue: add const to less comparator
sed -i 's/bool operator ()(const node\* l, const node\* r) {return l->m_index < r->m_index;}/bool operator ()(const node* l, const node* r) const {return l->m_index < r->m_index;}/' include/yaml-cpp/node/detail/node.h

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/node"
cp "/tests/node/node_test.cpp" "test/node/node_test.cpp"

# Rebuild the test executable with the updated test files
cmake --build build --config Debug 2>&1
rebuild_status=$?

if [ $rebuild_status -ne 0 ]; then
  echo "Rebuild failed with status $rebuild_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $rebuild_status
fi

# Run only the specific tests from node_test.cpp
./build/test/run-tests --gtest_filter=NodeTest.*
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
