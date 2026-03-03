#!/bin/bash

cd /app/src

# Clean up buggy state - remove scripts from scripts/ if they exist there
rm -rf scripts/issue150.sh scripts/testjson2json.sh scripts/CMakeLists.txt

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/issue150.sh" "tests/issue150.sh"
chmod +x "tests/issue150.sh"
mkdir -p "tests"
cp "/tests/testjson2json.sh" "tests/testjson2json.sh"
chmod +x "tests/testjson2json.sh"

# Rebuild to include the updated test files
echo "Rebuilding with updated test files..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -DSIMDJSON_COMPETITION=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Build only the required test targets (not fuzz which has build errors)
    echo "Building test targets..."
    cmake --build build --target allparserscheckfile json2json minify -j=2 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "ERROR: Build failed"
        test_status=1
    else
        # Run slowtests via CTest (this should include issue150 and testjson2json)
        echo "Running slowtests via CTest..."
        cd build
        ctest --output-on-failure -L slowtests 2>&1
        slowtests_status=$?

        # Check that at least 2 slowtests ran (issue150 and testjson2json)
        num_tests=$(ctest -L slowtests -N 2>&1 | grep "Total Tests:" | awk '{print $3}')
        echo "Number of slowtests found: $num_tests"

        if [ "$slowtests_status" -ne 0 ]; then
            echo "ERROR: slowtests failed to run or had failures"
            test_status=1
        elif [ -z "$num_tests" ] || [ "$num_tests" -lt 2 ]; then
            echo "ERROR: Expected at least 2 slowtests (issue150 and testjson2json), found $num_tests"
            test_status=1
        else
            echo "SUCCESS: slowtests passed ($num_tests tests ran)"
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
