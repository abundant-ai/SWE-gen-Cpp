#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/readme_examples_noexceptions.cpp" "tests/readme_examples_noexceptions.cpp"

# Reconfigure CMake to pick up the restored test files
# Force-define SIMDJSON_DEVELOPMENT_CHECKS via compiler flags since the buggy state renamed it to SIMDJSON_ONDEMAND_SAFETY_RAILS
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -DCMAKE_CXX_FLAGS="-DSIMDJSON_DEVELOPMENT_CHECKS" -B build

# Build and run the specific test targets for this PR
test_status=0

# Build the specific test executables related to basictests and readme_examples_noexceptions
if ! cmake --build build --target basictests -j=2; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target readme_examples_noexceptions -j=2; then
    test_status=1
  fi
fi

# Run the specific tests
if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^basictests$|^readme_examples_noexceptions$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
