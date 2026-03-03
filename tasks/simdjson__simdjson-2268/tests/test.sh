#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_custom_types_tests.cpp" "tests/ondemand/ondemand_custom_types_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_stl_types_tests.cpp" "tests/ondemand/ondemand_stl_types_tests.cpp"
mkdir -p "tests"
cp "/tests/test_macros.h" "tests/test_macros.h"

# Build and run the ondemand test executables
test_status=0

# Build ondemand/ondemand_custom_types_tests
if ! cmake --build build --target ondemand_custom_types_tests -j=2; then
  test_status=1
# Build ondemand/ondemand_stl_types_tests
elif ! cmake --build build --target ondemand_stl_types_tests -j=2; then
  test_status=1
# Run ondemand_custom_types_tests
elif ! ./build/tests/ondemand/ondemand_custom_types_tests; then
  test_status=1
# Run ondemand_stl_types_tests
elif ! ./build/tests/ondemand/ondemand_stl_types_tests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
