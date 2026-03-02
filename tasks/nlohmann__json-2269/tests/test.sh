#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
cp "/tests/Makefile" "test/Makefile"
mkdir -p "test/src"
cp "/tests/src/unit-hash.cpp" "test/src/unit-hash.cpp"

# Rebuild the tests to incorporate the HEAD test files
cd build
cmake --build . --target test-hash

# Run the specific unit tests
ctest -R "test-hash" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
