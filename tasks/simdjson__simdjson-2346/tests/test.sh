#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/json_path_tests.cpp" "tests/dom/json_path_tests.cpp"
mkdir -p "tests/dom"
cp "/tests/dom/readme_examples.cpp" "tests/dom/readme_examples.cpp"

# json_path_tests is a regular test executable - rebuild and run it
if ! cmake --build build --target json_path_tests -j=2; then
  test_status=1
elif ! ./build/tests/dom/json_path_tests; then
  test_status=1
# readme_examples is COMPILE_ONLY - just building it is the test
elif ! cmake --build build --target readme_examples -j=2; then
  test_status=1
else
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
