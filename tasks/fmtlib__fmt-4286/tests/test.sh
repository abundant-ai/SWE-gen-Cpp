#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/std-test.cc" "test/std-test.cc"
mkdir -p "test"
cp "/tests/xchar-test.cc" "test/xchar-test.cc"

# Reconfigure and rebuild to pick up any changes and new test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cmake --build build --target std-test --target xchar-test --parallel $(nproc)
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific test binaries for std-test and xchar-test
./build/bin/std-test && ./build/bin/xchar-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
