#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/basictests.cpp" "tests/dom/basictests.cpp"
mkdir -p "tests/dom"
cp "/tests/dom/document_stream_tests.cpp" "tests/dom/document_stream_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_document_stream_tests.cpp" "tests/ondemand/ondemand_document_stream_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_misc_tests.cpp" "tests/ondemand/ondemand_misc_tests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the test executables
test_status=0

# Build basictests
if ! cmake --build build --target basictests -j=2; then
  test_status=1
# Run basictests
elif ! ./build/tests/dom/basictests; then
  test_status=1
# Build document_stream_tests
elif ! cmake --build build --target document_stream_tests -j=2; then
  test_status=1
# Run document_stream_tests
elif ! ./build/tests/dom/document_stream_tests; then
  test_status=1
# Build ondemand_document_stream_tests
elif ! cmake --build build --target ondemand_document_stream_tests -j=2; then
  test_status=1
# Run ondemand_document_stream_tests
elif ! ./build/tests/ondemand/ondemand_document_stream_tests; then
  test_status=1
# Build ondemand_misc_tests
elif ! cmake --build build --target ondemand_misc_tests -j=2; then
  test_status=1
# Run ondemand_misc_tests
elif ! ./build/tests/ondemand/ondemand_misc_tests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
