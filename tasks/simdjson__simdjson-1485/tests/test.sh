#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_compilation_tests.cpp" "tests/ondemand/ondemand_compilation_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_object_tests.cpp" "tests/ondemand/ondemand_object_tests.cpp"

# Reconfigure CMake to pick up the restored test files
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the specific test targets for this PR
test_status=0

# Build the specific test executables related to ondemand tests
if ! cmake --build build --target ondemand_compilation_tests ondemand_object_tests -j=2; then
  test_status=1
fi

# Run the specific tests
if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^(ondemand_compilation_tests|ondemand_object_tests)$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
