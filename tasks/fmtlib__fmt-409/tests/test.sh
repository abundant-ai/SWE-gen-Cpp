#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/mock-allocator.h" "test/mock-allocator.h"
mkdir -p "test"
cp "/tests/util-test.cc" "test/util-test.cc"

# Clean build directory to avoid CMake cache issues
rm -rf build

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=14 \
    -DFMT_TEST=ON 2>&1

# Build the specific test targets
cmake --build build --target format-test --parallel $(nproc) 2>&1
format_test_build=$?

cmake --build build --target util-test --parallel $(nproc) 2>&1
util_test_build=$?

# If build failed, exit with error
if [ $format_test_build -ne 0 ] || [ $util_test_build -ne 0 ]; then
  echo "Build failed"
  test_status=1
else
  # Run the format-test
  ./build/bin/format-test
  format_test_status=$?

  # Run the util-test
  ./build/bin/util-test
  util_test_status=$?

  # Both must pass
  if [ $format_test_status -eq 0 ] && [ $util_test_status -eq 0 ]; then
    test_status=0
  else
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
