#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-cbor.cpp" "test/src/unit-cbor.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-msgpack.cpp" "test/src/unit-msgpack.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-ubjson.cpp" "test/src/unit-ubjson.cpp"

# Rebuild and run the specific tests using CMake
build_output=$(cmake --build build --target test-cbor test-msgpack test-regression test-ubjson 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run test-cbor and capture output
    test_output_cbor=$(./build/test/test-cbor 2>&1)
    test_status_cbor=$?
    echo "$test_output_cbor"

    # Run test-msgpack and capture output
    test_output_msgpack=$(./build/test/test-msgpack 2>&1)
    test_status_msgpack=$?
    echo "$test_output_msgpack"

    # Run test-regression and capture output
    test_output_regression=$(./build/test/test-regression 2>&1)
    test_status_regression=$?
    echo "$test_output_regression"

    # Run test-ubjson and capture output
    test_output_ubjson=$(./build/test/test-ubjson 2>&1)
    test_status_ubjson=$?
    echo "$test_output_ubjson"

    # Check if any test failed
    if [ $test_status_cbor -ne 0 ] || [ $test_status_msgpack -ne 0 ] || [ $test_status_regression -ne 0 ] || [ $test_status_ubjson -ne 0 ]; then
        test_status=1
    else
        test_status=0
    fi

    # Check if "No tests ran" appears in output (means test section doesn't exist)
    if echo "$test_output_cbor" | grep -q "No tests ran"; then
        test_status=1
    fi
    if echo "$test_output_msgpack" | grep -q "No tests ran"; then
        test_status=1
    fi
    if echo "$test_output_regression" | grep -q "No tests ran"; then
        test_status=1
    fi
    if echo "$test_output_ubjson" | grep -q "No tests ran"; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
