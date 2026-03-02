#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-hash.cpp" "test/src/unit-hash.cpp"

# Rebuild the test executable with the updated test file
if ! cmake --build build --target test-hash; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable for unit-hash.cpp
./build/test/test-hash
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
