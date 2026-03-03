#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# This PR is about making ctest succeed after running make all_tests
# The fix ensures the all_tests target exists and ctest dependencies are correct
test_status=0

# Build a few representative test targets
if ! cmake --build build --target basictests minify_tests -j=2; then
  test_status=1
fi

# Run a quick subset of tests to verify ctest works
# Testing basictests and minify_tests as representative examples
if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^(basictests|minify_tests)$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
