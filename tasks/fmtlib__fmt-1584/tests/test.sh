#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/format-dyn-args-test.cc" "test/format-dyn-args-test.cc"

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON

# Build the specific test binary
cmake --build build --target format-dyn-args-test

# Run the specific test
./build/bin/format-dyn-args-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
