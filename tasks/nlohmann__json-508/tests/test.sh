#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-conversions.cpp" "test/src/unit-conversions.cpp"

# Build a standalone test executable for unit-conversions.cpp
# This avoids C++17 compatibility issues with the full json_unit executable
echo "Building standalone conversions test..."

# Compile catch_main object file
/usr/bin/clang++-14 -c test/src/unit.cpp -o /tmp/unit.o \
    -Itest/thirdparty/catch \
    -std=c++17

if [ $? -ne 0 ]; then
    echo "Failed to compile catch_main"
    test_status=1
else
    # Compile and link the conversions test
    /usr/bin/clang++-14 test/src/unit-conversions.cpp /tmp/unit.o \
        -o /tmp/test-conversions \
        -Isrc -Itest/thirdparty/catch \
        -std=c++17

    if [ $? -ne 0 ]; then
        echo "Failed to compile test-conversions"
        test_status=1
    else
        # Run the test
        echo "Running conversions tests..."
        test_output=$(/tmp/test-conversions 2>&1)
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
