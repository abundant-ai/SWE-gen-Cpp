#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/builder"
cp "/tests/builder/CMakeLists.txt" "tests/builder/CMakeLists.txt"
mkdir -p "tests/builder"
cp "/tests/builder/static_reflection_fractured_json_tests.cpp" "tests/builder/static_reflection_fractured_json_tests.cpp"
mkdir -p "tests/dom"
cp "/tests/dom/basictests.cpp" "tests/dom/basictests.cpp"
mkdir -p "tests"
cp "/tests/fractured_json_tests.cpp" "tests/fractured_json_tests.cpp"

# Rebuild all tests after copying the updated test files
# If build fails, the test fails
if ! cmake --build build -j=2; then
  test_status=1
else
  # Run the specific test executables
  test_status=0

  # Run fractured_json_tests
  if [ -x ./build/tests/fractured_json_tests ]; then
    ./build/tests/fractured_json_tests || test_status=1
  fi

  # Run static_reflection_fractured_json_tests if it exists (requires SIMDJSON_STATIC_REFLECTION)
  if [ -x ./build/tests/builder/static_reflection_fractured_json_tests ]; then
    ./build/tests/builder/static_reflection_fractured_json_tests || test_status=1
  fi

  # Run basictests
  if [ -x ./build/tests/dom/basictests ]; then
    ./build/tests/dom/basictests || test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
