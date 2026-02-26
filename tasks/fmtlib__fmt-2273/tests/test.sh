#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/gtest-extra-test.cc" "test/gtest-extra-test.cc"
mkdir -p "test"
cp "/tests/os-test.cc" "test/os-test.cc"
mkdir -p "test"
cp "/tests/posix-mock-test.cc" "test/posix-mock-test.cc"

# Build the specific test targets using CMake
cmake --build build --target gtest-extra-test
cmake --build build --target os-test
cmake --build build --target posix-mock-test

# Run the test executables
./build/bin/gtest-extra-test
gtest_status=$?

./build/bin/os-test
os_status=$?

./build/bin/posix-mock-test
posix_status=$?

# Check if all tests passed
if [ $gtest_status -eq 0 ] && [ $os_status -eq 0 ] && [ $posix_status -eq 0 ]; then
  test_status=0
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
