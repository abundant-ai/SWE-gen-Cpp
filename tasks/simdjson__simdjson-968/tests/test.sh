#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/cast_tester.h" "tests/cast_tester.h"

# The fix updates method names in cast_tester.h from get_int64_t() to get_int64()
# Test: Verify that basictests.cpp (which includes cast_tester.h) compiles successfully
echo "Testing that cast_tester.h compiles correctly with basictests.cpp..."

# Rebuild to pick up the updated cast_tester.h
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Try to build basictests target which includes cast_tester.h
    echo "Building basictests target (uses cast_tester.h)..."
    cmake --build build --target basictests 2>&1
    test_status=$?

    if [ $test_status -eq 0 ]; then
        echo "SUCCESS: cast_tester.h compiles correctly"
    else
        echo "ERROR: Failed to compile basictests with cast_tester.h"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
