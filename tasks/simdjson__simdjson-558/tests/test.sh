#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/numberparsingcheck.cpp" "tests/numberparsingcheck.cpp"

# Rebuild library using CMake
echo "Rebuilding library..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    echo "Building simdjson library..."
    cmake --build build --target simdjson -j=2 2>&1
    lib_build_status=$?

    if [ $lib_build_status -ne 0 ]; then
        echo "ERROR: Library build failed"
        test_status=1
    else
        # Compile and run basictests
        echo "Compiling basictests test..."
        g++ -std=c++20 -I include -L build -o build/basictests tests/basictests.cpp -lsimdjson 2>&1
        basictests_compile=$?

        if [ $basictests_compile -ne 0 ]; then
            echo "ERROR: basictests compilation failed"
            test_status=1
        else
            echo "Running basictests..."
            LD_LIBRARY_PATH=build ./build/basictests 2>&1
            basictests_status=$?

            if [ $basictests_status -ne 0 ]; then
                echo "ERROR: basictests failed"
                test_status=1
            else
                # Compile and run numberparsingcheck (includes simdjson.cpp directly)
                echo "Compiling numberparsingcheck test..."
                g++ -std=c++20 -I include -I src -o build/numberparsingcheck tests/numberparsingcheck.cpp 2>&1
                numberparsingcheck_compile=$?

                if [ $numberparsingcheck_compile -ne 0 ]; then
                    echo "ERROR: numberparsingcheck compilation failed"
                    test_status=1
                else
                    echo "Running numberparsingcheck..."
                    ./build/numberparsingcheck 2>&1
                    numberparsingcheck_status=$?

                    if [ $numberparsingcheck_status -eq 0 ]; then
                        echo "SUCCESS: All tests passed"
                        test_status=0
                    else
                        echo "ERROR: numberparsingcheck failed"
                        test_status=1
                    fi
                fi
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
