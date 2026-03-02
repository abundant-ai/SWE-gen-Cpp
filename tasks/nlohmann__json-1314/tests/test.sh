#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-serialization.cpp" "test/src/unit-serialization.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-unicode.cpp" "test/src/unit-unicode.cpp"

# Rebuild and run the specific tests using CMake
build_output=$(cmake --build build --target test-serialization test-unicode 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run test-serialization and capture output
    test_output_serialization=$(./build/test/test-serialization 2>&1)
    test_status_serialization=$?
    echo "$test_output_serialization"

    # Run test-unicode and capture output
    test_output_unicode=$(./build/test/test-unicode 2>&1)
    test_status_unicode=$?
    echo "$test_output_unicode"

    # Check if either test failed
    if [ $test_status_serialization -ne 0 ] || [ $test_status_unicode -ne 0 ]; then
        test_status=1
    else
        test_status=0
    fi

    # Check if "No tests ran" appears in output (means test section doesn't exist)
    if echo "$test_output_serialization" | grep -q "No tests ran"; then
        test_status=1
    fi
    if echo "$test_output_unicode" | grep -q "No tests ran"; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
