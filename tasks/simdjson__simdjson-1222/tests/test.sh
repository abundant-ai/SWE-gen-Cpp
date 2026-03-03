#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/numberparsingcheck.cpp" "tests/numberparsingcheck.cpp"
mkdir -p "tests"
cp "/tests/random_string_number_tests.cpp" "tests/random_string_number_tests.cpp"

# Configure CMake
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_ONDEMAND_SAFETY_RAILS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build the simdjson library
cmake --build build --target simdjson -j=2

# Build and run the specific test binaries
cmake --build build --target basictests -j=2
cmake --build build --target numberparsingcheck -j=2
cmake --build build --target random_string_number_tests -j=2

# Run the tests
./build/tests/basictests
test_status=$?

if [ $test_status -eq 0 ]; then
  ./build/tests/numberparsingcheck
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  ./build/tests/random_string_number_tests
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
