#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/CMakeLists.txt" "tests/compilation_failure_tests/CMakeLists.txt"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/dangling_parser_load.cpp" "tests/compilation_failure_tests/dangling_parser_load.cpp"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/dangling_parser_parse_padstring.cpp" "tests/compilation_failure_tests/dangling_parser_parse_padstring.cpp"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/dangling_parser_parse_stdstring.cpp" "tests/compilation_failure_tests/dangling_parser_parse_stdstring.cpp"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/dangling_parser_parse_uchar.cpp" "tests/compilation_failure_tests/dangling_parser_parse_uchar.cpp"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/dangling_parser_parse_uint8.cpp" "tests/compilation_failure_tests/dangling_parser_parse_uint8.cpp"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/example_compiletest.cpp" "tests/compilation_failure_tests/example_compiletest.cpp"

# Rebuild to include compilation failure tests
echo "Rebuilding with compilation failure tests..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Run compilation failure tests with ctest
    # These tests verify that certain code fails to compile as expected
    echo "Running compilation failure tests..."
    cd build
    ctest -R "example_compiletest|dangling_parser_load|dangling_parser_parse_uint8|dangling_parser_parse_uchar|dangling_parser_parse_stdstring|dangling_parser_parse_padstring" --output-on-failure 2>&1
    test_status=$?
    cd ..

    if [ $test_status -eq 0 ]; then
        echo "SUCCESS: All compilation failure tests passed"
    else
        echo "ERROR: Compilation failure tests failed"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
