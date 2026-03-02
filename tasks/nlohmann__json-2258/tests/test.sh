#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/src"
cp "/tests/src/unit-ordered_json.cpp" "test/src/unit-ordered_json.cpp"

# Rebuild the tests to incorporate the HEAD test files
cd build
cmake --build . --target test-ordered_json

# Run the specific unit tests
ctest -R "test-ordered_json" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
