#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/integration"
cp "/tests/integration/emitter_test.cpp" "test/integration/emitter_test.cpp"

# Rebuild the test binary with the updated test file
cd build
make -j2 yaml-cpp-tests

# Run only tests from EmitterTest suite (from emitter_test.cpp)
./test/yaml-cpp-tests --gtest_filter="EmitterTest.*"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
