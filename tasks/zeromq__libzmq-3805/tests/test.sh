#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/testutil.hpp" "tests/testutil.hpp"

# Rebuild from scratch to ensure clean state
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Try to build unittest_curve_encoding - this will only succeed if it's in CMakeLists
make -j$(nproc) unittest_curve_encoding
test_status=$?

if [ $test_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit $test_status
fi

# Run the unittest
cd /app/src
./build/bin/unittest_curve_encoding
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
