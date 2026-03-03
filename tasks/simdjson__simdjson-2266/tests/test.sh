#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/CMakeLists.txt" "tests/dom/CMakeLists.txt"
mkdir -p "tests/dom"
cp "/tests/dom/json_path_tests.cpp" "tests/dom/json_path_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_json_path_tests.cpp" "tests/ondemand/ondemand_json_path_tests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the json_path test executables
test_status=0

# Build dom/json_path_tests
if ! cmake --build build --target json_path_tests -j=2; then
  test_status=1
# Build ondemand/ondemand_json_path_tests
elif ! cmake --build build --target ondemand_json_path_tests -j=2; then
  test_status=1
# Run json_path_tests
elif ! ./build/tests/dom/json_path_tests; then
  test_status=1
# Run ondemand_json_path_tests
elif ! ./build/tests/ondemand/ondemand_json_path_tests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
