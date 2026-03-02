#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/builder"
cp "/tests/builder/builder_string_builder_tests.cpp" "tests/builder/builder_string_builder_tests.cpp"

# Rebuild the specific test after copying the updated test file
# If build fails, the test fails
if ! cmake --build build --target builder_string_builder_tests -j=2; then
  test_status=1
else
  # Run the specific test executable
  ./build/tests/builder/builder_string_builder_tests
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
