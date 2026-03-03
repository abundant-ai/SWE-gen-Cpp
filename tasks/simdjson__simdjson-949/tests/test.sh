#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/cast_tester.h" "tests/cast_tester.h"
mkdir -p "tests"
cp "/tests/test_macros.h" "tests/test_macros.h"

# The PR updates test_macros.h header file
# Test: Verify that basictests.cpp (which includes test_macros.h) compiles successfully
echo "Testing that test_macros.h compiles correctly with basictests.cpp..."

# Rebuild to pick up the updated test_macros.h
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Try to build basictests target which includes test_macros.h
    echo "Building basictests target (uses test_macros.h)..."
    cmake --build build --target basictests 2>&1
    test_status=$?

    if [ $test_status -eq 0 ]; then
        echo "SUCCESS: test_macros.h compiles correctly"
    else
        echo "ERROR: Failed to compile basictests with test_macros.h"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
