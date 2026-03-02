#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/mock-allocator.h" "test/mock-allocator.h"
mkdir -p "test"
cp "/tests/util-test.cc" "test/util-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild and run the specific tests for this PR
cd build
rm -rf *

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DFMT_TEST=ON \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++

# Build and run format-test
make format-test
if [ $? -eq 0 ]; then
  ./bin/format-test
  test_status=$?
else
  test_status=1
fi

# Build and run util-test if format-test passed
if [ $test_status -eq 0 ]; then
  make util-test
  if [ $? -eq 0 ]; then
    ./bin/util-test
    test_status=$?
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
