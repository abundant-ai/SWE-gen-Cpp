#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-pointer_access.cpp" "tests/src/unit-pointer_access.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-reference_access.cpp" "tests/src/unit-reference_access.cpp"

# Rebuild the test executables with the updated test files
cmake --build build --target test-pointer_access_cpp11
cmake --build build --target test-reference_access_cpp11

# Run the specific test executables
build/tests/test-pointer_access_cpp11 && build/tests/test-reference_access_cpp11
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
