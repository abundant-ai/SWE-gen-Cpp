#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/jsoncheck.cpp" "tests/jsoncheck.cpp"
mkdir -p "tests"
cp "/tests/pointercheck.cpp" "tests/pointercheck.cpp"
mkdir -p "tests"
cp "/tests/readme_examples.cpp" "tests/readme_examples.cpp"

# Rebuild the specific tests
cmake --build build --target jsoncheck
cmake --build build --target pointercheck
cmake --build build --target readme_examples

# Run the specific tests
./build/tests/jsoncheck && ./build/tests/pointercheck
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
