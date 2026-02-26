#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/container-test.cc" "test/container-test.cc"

# Clean build directory to avoid CMake cache issues
rm -rf build

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=14 \
    -DFMT_TEST=ON 2>&1

# Build the specific test target (capture both stdout and stderr)
cmake --build build --target container-test --parallel $(nproc) 2>&1
build_status=$?

# If build failed, exit with error
if [ $build_status -ne 0 ]; then
  echo "Build failed"
  test_status=1
else
  # Run the test
  ./build/bin/container-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
