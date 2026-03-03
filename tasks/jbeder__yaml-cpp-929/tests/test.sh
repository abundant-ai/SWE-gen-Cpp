#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/integration"
cp "/tests/integration/emitter_test.cpp" "test/integration/emitter_test.cpp"

# Rebuild the test executable with the updated test file
cmake --build build --config Debug 2>&1
rebuild_status=$?

if [ $rebuild_status -ne 0 ]; then
  echo "Rebuild failed with status $rebuild_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $rebuild_status
fi

# Run only the EmitterTest tests from emitter_test.cpp
./build/test/yaml-cpp-tests --gtest_filter=EmitterTest.*
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
