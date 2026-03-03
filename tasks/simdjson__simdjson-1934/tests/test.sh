#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/checkimplementation.cpp" "tests/checkimplementation.cpp"
mkdir -p "tests/dom"
cp "/tests/dom/readme_examples.cpp" "tests/dom/readme_examples.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_document_stream_tests.cpp" "tests/ondemand/ondemand_document_stream_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_number_in_string_tests.cpp" "tests/ondemand/ondemand_number_in_string_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_scalar_tests.cpp" "tests/ondemand/ondemand_scalar_tests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the test executables
test_status=0

# Build checkimplementation
if ! cmake --build build --target checkimplementation -j=2; then
  test_status=1
# Run checkimplementation
elif ! ./build/tests/checkimplementation; then
  test_status=1
# Build readme_examples
elif ! cmake --build build --target readme_examples -j=2; then
  test_status=1
# Run readme_examples
elif ! ./build/tests/dom/readme_examples; then
  test_status=1
# Build ondemand_document_stream_tests
elif ! cmake --build build --target ondemand_document_stream_tests -j=2; then
  test_status=1
# Run ondemand_document_stream_tests
elif ! ./build/tests/ondemand/ondemand_document_stream_tests; then
  test_status=1
# Build ondemand_number_in_string_tests
elif ! cmake --build build --target ondemand_number_in_string_tests -j=2; then
  test_status=1
# Run ondemand_number_in_string_tests
elif ! ./build/tests/ondemand/ondemand_number_in_string_tests; then
  test_status=1
# Build ondemand_scalar_tests
elif ! cmake --build build --target ondemand_scalar_tests -j=2; then
  test_status=1
# Run ondemand_scalar_tests
elif ! ./build/tests/ondemand/ondemand_scalar_tests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
