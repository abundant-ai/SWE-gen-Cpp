#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/unit.cpp" "test/unit.cpp"

# Build and run the test
echo "Building and running test..."

# Compile and run the test file directly
compile_output=$(/usr/bin/clang++-14 test/unit.cpp \
    -o /tmp/test-unit \
    -Isrc -Itest \
    -std=c++11 2>&1)
compile_status=$?

if [ $compile_status -ne 0 ]; then
    echo "Failed to compile test-unit"
    echo "$compile_output"
    test_status=1
else
    echo "Running unit tests..."
    test_output=$(/tmp/test-unit 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    else
        test_status=0
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
