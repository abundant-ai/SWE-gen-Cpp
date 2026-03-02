#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-conversions.cpp" "test/src/unit-conversions.cpp"

# Rebuild and run the specific test using CMake
build_output=$(cmake --build build --target test-conversions 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run the test and capture output
    test_output=$(./build/test/test-conversions 2>&1)
    test_status=$?

    # Print the output so it appears in logs
    echo "$test_output"

    # Check if "No tests ran" appears in output (means test section doesn't exist)
    if echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
