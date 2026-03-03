#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/parse_many_test.cpp" "tests/parse_many_test.cpp"

# Rebuild project and tests using CMake
echo "Rebuilding project with tests..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Build the specific test targets
    echo "Building basictests and parse_many_test..."
    cmake --build build --target basictests -j=2 2>&1
    basictests_build_status=$?

    cmake --build build --target parse_many_test -j=2 2>&1
    parse_many_build_status=$?

    if [ $basictests_build_status -ne 0 ] || [ $parse_many_build_status -ne 0 ]; then
        echo "ERROR: Test build failed"
        test_status=1
    else
        # Run the test executables
        echo "Running basictests..."
        ./build/tests/basictests 2>&1
        basictests_status=$?

        echo "Running parse_many_test..."
        ./build/tests/parse_many_test 2>&1
        parse_many_status=$?

        # Check if both tests passed
        if [ $basictests_status -eq 0 ] && [ $parse_many_status -eq 0 ]; then
            echo "SUCCESS: All tests passed"
            test_status=0
        else
            echo "ERROR: Tests failed (basictests=$basictests_status, parse_many_test=$parse_many_status)"
            test_status=1
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
