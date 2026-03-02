#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-udt.cpp" "test/src/unit-udt.cpp"

# Rebuild the test executables with the updated test files
if ! cmake --build build --target test-udt; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable for unit-udt.cpp
./build/test/test-udt
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
