#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/allparserscheckfile.cpp" "tests/allparserscheckfile.cpp"
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/integer_tests.cpp" "tests/integer_tests.cpp"
mkdir -p "tests"
cp "/tests/jsoncheck.cpp" "tests/jsoncheck.cpp"
mkdir -p "tests"
cp "/tests/numberparsingcheck.cpp" "tests/numberparsingcheck.cpp"
mkdir -p "tests"
cp "/tests/singleheadertest.cpp" "tests/singleheadertest.cpp"
mkdir -p "tests"
cp "/tests/stringparsingcheck.cpp" "tests/stringparsingcheck.cpp"

# Rebuild project and tests using CMake
echo "Rebuilding project with tests..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Build only the test targets that exist in CMakeLists.txt
    echo "Building test targets..."
    (cmake --build build --target basictests -j=2 && \
     cmake --build build --target integer_tests -j=2 && \
     cmake --build build --target jsoncheck -j=2) 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "ERROR: Test build failed"
        test_status=1
    else
        # Run the test executables
        test_status=0

        echo "Running basictests..."
        ./build/tests/basictests 2>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: basictests failed"
            test_status=1
        fi

        echo "Running integer_tests..."
        ./build/tests/integer_tests 2>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: integer_tests failed"
            test_status=1
        fi

        echo "Running jsoncheck..."
        ./build/tests/jsoncheck 2>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: jsoncheck failed"
            test_status=1
        fi

        if [ $test_status -eq 0 ]; then
            echo "SUCCESS: All tests passed"
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
