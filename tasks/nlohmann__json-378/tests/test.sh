#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"

# Build standalone test executables for each test file
echo "Building standalone tests..."

# Compile catch_main object file
/usr/bin/clang++-14 -c test/src/unit.cpp -o /tmp/unit.o \
    -Itest/thirdparty/catch \
    -std=c++11

if [ $? -ne 0 ]; then
    echo "Failed to compile catch_main"
    test_status=1
else
    # Compile and link the test file
    compile_output=$(/usr/bin/clang++-14 test/src/unit-regression.cpp /tmp/unit.o \
        -o /tmp/test-regression \
        -Isrc -Itest/thirdparty/catch \
        -std=c++11 2>&1)
    compile_status=$?

    if [ $compile_status -ne 0 ]; then
        echo "Failed to compile test-regression"
        echo "$compile_output"
        test_status=1
    else
        echo "Running unit-regression tests..."
        test_output=$(/tmp/test-regression 2>&1)
        test_exit=$?
        echo "$test_output"
        if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
            test_status=1
        else
            test_status=0
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
