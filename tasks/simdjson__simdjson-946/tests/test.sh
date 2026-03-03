#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"

# Rebuild and compile basictests to verify the changes
echo "Testing that basictests.cpp compiles correctly..."

# Rebuild to pick up the updated test file
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Try to build basictests target
    echo "Building basictests target..."
    cmake --build build --target basictests 2>&1
    test_status=$?

    if [ $test_status -eq 0 ]; then
        echo "SUCCESS: basictests compiled correctly"
    else
        echo "ERROR: Failed to compile basictests"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
