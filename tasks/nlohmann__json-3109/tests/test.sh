#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-ordered_map.cpp" "test/src/unit-ordered_map.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"

# Rebuild the test executable with the updated test file
# Note: Only building test-ordered_map as test-regression2 has unrelated compilation issues with GCC 13.3
if ! cmake --build build --target test-ordered_map; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable for unit-ordered_map.cpp
./build/test/test-ordered_map
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
