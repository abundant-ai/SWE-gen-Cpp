#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/minify_tests.cpp" "tests/minify_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/CMakeLists.txt" "tests/ondemand/CMakeLists.txt"
cp "/tests/ondemand/ondemand_tostring_tests.cpp" "tests/ondemand/ondemand_tostring_tests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the test executables
test_status=0

# Build and run minify_tests
if ! cmake --build build --target minify_tests -j=2; then
  test_status=1
elif ! timeout 30 ./build/tests/minify_tests; then
  test_status=1
fi

# Build and run ondemand_tostring_tests
if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_tostring_tests -j=2; then
    test_status=1
  elif ! timeout 30 ./build/tests/ondemand/ondemand_tostring_tests; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
