#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/pointercheck.cpp" "tests/dom/pointercheck.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_json_pointer_tests.cpp" "tests/ondemand/ondemand_json_pointer_tests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the test executables
test_status=0

# Build pointercheck
if ! cmake --build build --target pointercheck -j=2; then
  test_status=1
# Run pointercheck
elif ! ./build/tests/dom/pointercheck; then
  test_status=1
# Build ondemand_json_pointer_tests
elif ! cmake --build build --target ondemand_json_pointer_tests -j=2; then
  test_status=1
# Run ondemand_json_pointer_tests
elif ! ./build/tests/ondemand/ondemand_json_pointer_tests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
