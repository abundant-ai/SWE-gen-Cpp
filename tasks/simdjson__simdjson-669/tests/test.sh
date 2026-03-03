#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/readme_examples.cpp" "tests/readme_examples.cpp"

# Rebuild to include the updated test files
echo "Rebuilding with updated test files..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Build the test targets
    echo "Building test targets..."
    cmake --build build --target basictests -j=2 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "ERROR: Build failed"
        test_status=1
    else
        # Run basictests
        echo "Running basictests..."
        ./build/tests/basictests 2>&1
        test_status=$?

        if [ "$test_status" -ne 0 ]; then
            echo "ERROR: basictests failed"
        else
            echo "SUCCESS: basictests passed"
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
