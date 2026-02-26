#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/color-test.cc" "test/color-test.cc"

# Reconfigure and rebuild to pick up any changes and new test file
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cmake --build build --parallel $(nproc)
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific color test binary
./build/bin/color-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
