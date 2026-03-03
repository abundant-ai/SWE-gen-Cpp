#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_misc_tests.cpp" "tests/ondemand/ondemand_misc_tests.cpp"

# ondemand_misc_tests is a regular test executable - rebuild and run it
if ! cmake --build build --target ondemand_misc_tests -j=2; then
  test_status=1
elif ! ./build/tests/ondemand/ondemand_misc_tests; then
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
