#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"

# Rebuild and run the specific tests using CMake
build_output=$(cmake --build build --target test-regression 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run test-regression and capture output
    test_output_regression=$(./build/test/test-regression 2>&1)
    test_status_regression=$?
    echo "$test_output_regression"

    test_status=$test_status_regression

    # Check if "No tests ran" appears in output (means test section doesn't exist)
    if echo "$test_output_regression" | grep -q "No tests ran"; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
