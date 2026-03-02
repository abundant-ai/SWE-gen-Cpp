#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/external_definition"
cp "/tests/external_definition/main.cpp" "tests/external_definition/main.cpp"
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Rebuild the test executables from the updated test files
cd build
cmake --build . --target unittest
build_status_1=$?

# For external_definition, successful compilation is the test (it's a server app, not a test suite)
cmake --build . --target test_external_definition
build_status_2=$?

# If either build fails, tests fail
if [ $build_status_1 -ne 0 ] || [ $build_status_2 -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the unittest binary (external_definition is a server app, so we only test compilation)
timeout 30 ./tests/unittest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
