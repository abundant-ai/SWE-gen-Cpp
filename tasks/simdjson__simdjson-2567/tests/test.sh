#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/builder"
cp "/tests/builder/builder_string_builder_tests.cpp" "tests/builder/builder_string_builder_tests.cpp"
mkdir -p "tests/compile_time"
cp "/tests/compile_time/compile_time_json_tests.cpp" "tests/compile_time/compile_time_json_tests.cpp"

# Force rebuild of the specific test targets after copying updated files
rm -f ./build/tests/builder/builder_string_builder_tests
rm -f ./build/tests/compile_time/compile_time_json_tests

# Rebuild all tests after copying the updated test files
# If build fails, the test fails
if ! cmake --build build -j=2; then
  test_status=1
else
  # Run the specific test executables
  test_status=0

  # Run builder_string_builder_tests
  if [ -x ./build/tests/builder/builder_string_builder_tests ]; then
    ./build/tests/builder/builder_string_builder_tests || test_status=1
  fi

  # Run compile_time_json_tests
  if [ -x ./build/tests/compile_time/compile_time_json_tests ]; then
    ./build/tests/compile_time/compile_time_json_tests || test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
