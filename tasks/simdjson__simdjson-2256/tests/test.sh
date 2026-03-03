#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_custom_types_document_tests.cpp" "tests/ondemand/ondemand_custom_types_document_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_custom_types_tests.cpp" "tests/ondemand/ondemand_custom_types_tests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the custom types test executables
test_status=0

# Build ondemand/ondemand_custom_types_tests
if ! cmake --build build --target ondemand_custom_types_tests -j=2; then
  test_status=1
# Build ondemand/ondemand_custom_types_document_tests
elif ! cmake --build build --target ondemand_custom_types_document_tests -j=2; then
  test_status=1
# Run ondemand_custom_types_tests
elif ! ./build/tests/ondemand/ondemand_custom_types_tests; then
  test_status=1
# Run ondemand_custom_types_document_tests
elif ! ./build/tests/ondemand/ondemand_custom_types_document_tests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
