#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_error_tests.cpp" "tests/ondemand/ondemand_error_tests.cpp"
cp "/tests/ondemand/ondemand_readme_examples.cpp" "tests/ondemand/ondemand_readme_examples.cpp"

# Rebuild the specific test executables with the updated test files
# Build will fail in buggy state due to compilation errors when tests use missing operators
if ! cmake --build build --target ondemand_error_tests ondemand_readme_examples -j=2; then
  test_status=1
else
  # If build succeeded, run the specific test executables
  ./build/tests/ondemand/ondemand_error_tests && \
  ./build/tests/ondemand/ondemand_readme_examples
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
