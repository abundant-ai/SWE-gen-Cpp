#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/pointercheck.cpp" "tests/pointercheck.cpp"

# Rebuild simdjson library to include any code changes
echo "Rebuilding simdjson library..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    cmake --build build --target simdjson -j=2 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "ERROR: simdjson library build failed"
        test_status=1
    else
        # Compile and run basictests.cpp
        echo "Compiling basictests.cpp..."
        g++ -std=c++17 -o basictests tests/basictests.cpp -Iinclude -Isrc -Lbuild -lsimdjson 2>&1
        basictests_compile=$?

        # Compile and run pointercheck.cpp
        echo "Compiling pointercheck.cpp..."
        g++ -std=c++17 -o pointercheck tests/pointercheck.cpp -Iinclude -Isrc -Lbuild -lsimdjson 2>&1
        pointercheck_compile=$?

        if [ $basictests_compile -ne 0 ] || [ $pointercheck_compile -ne 0 ]; then
            echo "ERROR: Test compilation failed"
            test_status=1
        else
            echo "Running basictests..."
            LD_LIBRARY_PATH=build ./basictests 2>&1
            basictests_status=$?

            echo "Running pointercheck..."
            LD_LIBRARY_PATH=build ./pointercheck 2>&1
            pointercheck_status=$?

            if [ $basictests_status -ne 0 ] || [ $pointercheck_status -ne 0 ]; then
                echo "ERROR: Tests failed"
                test_status=1
            else
                echo "SUCCESS: Tests passed"
                test_status=0
            fi
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
