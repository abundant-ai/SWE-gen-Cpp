#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"
mkdir -p "test/data/json.org"
cp "/tests/data/json.org/1.json.bson" "test/data/json.org/1.json.bson"
mkdir -p "test/data/json.org"
cp "/tests/data/json.org/2.json.bson" "test/data/json.org/2.json.bson"
mkdir -p "test/data/json.org"
cp "/tests/data/json.org/3.json.bson" "test/data/json.org/3.json.bson"
mkdir -p "test/data/json.org"
cp "/tests/data/json.org/4.json.bson" "test/data/json.org/4.json.bson"
mkdir -p "test/data/json.org"
cp "/tests/data/json.org/5.json.bson" "test/data/json.org/5.json.bson"
mkdir -p "test/data/json_tests"
cp "/tests/data/json_tests/pass3.json.bson" "test/data/json_tests/pass3.json.bson"
mkdir -p "test/src"
cp "/tests/src/fuzzer-parse_bson.cpp" "test/src/fuzzer-parse_bson.cpp"
mkdir -p "test/src"
cp "/tests/src/fuzzer-parse_json.cpp" "test/src/fuzzer-parse_json.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-bson.cpp" "test/src/unit-bson.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"

# Rebuild and run the specific tests using CMake
build_output=$(cmake --build build --target test-bson test-regression 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run test-bson and capture output
    test_output_bson=$(./build/test/test-bson 2>&1)
    test_status_bson=$?
    echo "$test_output_bson"

    # Run test-regression and capture output
    test_output_regression=$(./build/test/test-regression 2>&1)
    test_status_regression=$?
    echo "$test_output_regression"

    # Check if either test failed
    if [ $test_status_bson -ne 0 ] || [ $test_status_regression -ne 0 ]; then
        test_status=1
    else
        test_status=0
    fi

    # Check if "No tests ran" appears in output (means test section doesn't exist)
    if echo "$test_output_bson" | grep -q "No tests ran"; then
        test_status=1
    fi
    if echo "$test_output_regression" | grep -q "No tests ran"; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
