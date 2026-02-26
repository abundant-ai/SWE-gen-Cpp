#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/static-export-test"
cp "/tests/static-export-test/CMakeLists.txt" "test/static-export-test/CMakeLists.txt"
mkdir -p "test/static-export-test"
cp "/tests/static-export-test/library.cc" "test/static-export-test/library.cc"
mkdir -p "test/static-export-test"
cp "/tests/static-export-test/main.cc" "test/static-export-test/main.cc"

# Build and run the static-export-test (standalone CMake project)
cd test/static-export-test
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=20

cmake --build build

# Run the test executable
./build/exe-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
