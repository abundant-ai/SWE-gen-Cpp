#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-udt_macro.cpp" "test/src/unit-udt_macro.cpp"

# Rebuild the test executable with the updated test file
if ! cmake --build build --target test-udt_macro; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable for unit-udt_macro.cpp
./build/test/test-udt_macro
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
