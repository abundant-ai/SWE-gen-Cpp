#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Rebuild only the unittest target with the updated test file (single-threaded to save memory)
# For this PR, compilation success/failure IS the test - deprecated APIs should fail to compile
cmake --build build --config Release --target unittest -- -j1
build_status=$?

# If build fails, tests fail (BASE with deprecated APIs should fail to compile)
if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit $build_status
fi

# Run the unittest executable (Catch2 framework)
./build/tests/unittest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
