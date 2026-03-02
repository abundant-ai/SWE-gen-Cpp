#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/src"
cp "/tests/src/unit-large_json.cpp" "test/src/unit-large_json.cpp"

# Rebuild and run the specific test using CMake
cmake --build build --target test-large_json || exit 1

# Run the test and capture output
test_output=$(./build/test/test-large_json "large_json" 2>&1)
test_status=$?

# Print the output so it appears in logs
echo "$test_output"

# Check if "No tests ran" appears in output (means test section doesn't exist)
if echo "$test_output" | grep -q "No tests ran"; then
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
