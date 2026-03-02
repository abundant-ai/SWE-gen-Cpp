#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/compile-test"
cp "/tests/compile-test/CMakeLists.txt" "test/compile-test/CMakeLists.txt"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild and run the compile tests
cd build
rm -rf *

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DFMT_TEST=ON \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DFMT_PEDANTIC=ON

if [ $? -ne 0 ]; then
  test_status=1
else
  # Run the compile-test via ctest
  ctest -R compile-test --output-on-failure
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
