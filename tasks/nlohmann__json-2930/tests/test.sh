#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-allocator.cpp" "test/src/unit-allocator.cpp"
cp "/tests/src/unit-deserialization.cpp" "test/src/unit-deserialization.cpp"
cp "/tests/src/unit-udt.cpp" "test/src/unit-udt.cpp"

# Copy the custom CMakeLists.txt that only builds the specific test files for this PR
cp /tests/CMakeLists.txt test/CMakeLists.txt

# Rebuild the test executables with the updated test files
cmake --build build --target test-allocator test-deserialization test-udt

# Run the specific tests for this PR
ctest --test-dir build -R "test-(allocator|deserialization|udt)$" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
