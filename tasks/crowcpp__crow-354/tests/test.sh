#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/multi_file"
cp "/tests/multi_file/CMakeLists.txt" "tests/multi_file/CMakeLists.txt"
cp "/tests/multi_file/main.cpp" "tests/multi_file/main.cpp"
cp "/tests/multi_file/secondary.cpp" "tests/multi_file/secondary.cpp"

# Reconfigure and build the multi_file test executable
cd build
cmake .. -DCROW_BUILD_TESTS=ON
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Build the test_multi_file target - this will fail in buggy state due to linking errors
cmake --build . --target test_multi_file
build_status=$?

if [ $build_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
