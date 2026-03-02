#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-cbor.cpp" "test/src/unit-cbor.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-class_parser.cpp" "test/src/unit-class_parser.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-deserialization.cpp" "test/src/unit-deserialization.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-json_pointer.cpp" "test/src/unit-json_pointer.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-msgpack.cpp" "test/src/unit-msgpack.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-ubjson.cpp" "test/src/unit-ubjson.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-unicode.cpp" "test/src/unit-unicode.cpp"

# Rebuild and run the specific tests using CMake
# Build targets for: unit-cbor, unit-class_parser, unit-deserialization, unit-json_pointer,
# unit-msgpack, unit-regression, unit-ubjson, unit-unicode
build_output=$(cmake --build build --target test-cbor test-class_parser test-deserialization test-json_pointer test-msgpack test-regression test-ubjson test-unicode 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run all test targets and track overall status
    test_status=0

    # Run test-cbor
    test_output=$(./build/test/test-cbor 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi

    # Run test-class_parser
    test_output=$(./build/test/test-class_parser 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi

    # Run test-deserialization
    test_output=$(./build/test/test-deserialization 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi

    # Run test-json_pointer
    test_output=$(./build/test/test-json_pointer 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi

    # Run test-msgpack
    test_output=$(./build/test/test-msgpack 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi

    # Run test-regression
    test_output=$(./build/test/test-regression 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi

    # Run test-ubjson
    test_output=$(./build/test/test-ubjson 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi

    # Run test-unicode
    test_output=$(./build/test/test-unicode 2>&1)
    test_exit=$?
    echo "$test_output"
    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
