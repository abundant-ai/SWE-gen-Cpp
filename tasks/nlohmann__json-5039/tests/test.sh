#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-cbor.cpp" "tests/src/unit-cbor.cpp"

# Rebuild the test with the updated code (from /tests)
cd build
cmake --build . --target test-cbor_cpp11

# Run the specific test executable, excluding tests that need external data files
cd tests
./test-cbor_cpp11 --test-case-exclude="*roundtrip*,*regressions*,*test suite*,*RFC 7049*"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
