#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/args-test.cc" "test/args-test.cc"

# Build the specific test using CMake
cd build
cmake --build . --target args-test
build_status=$?

if [ $build_status -ne 0 ]; then
  echo "Failed to build args-test" >&2
  test_status=1
else
  # Run the test executable
  ./bin/args-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
