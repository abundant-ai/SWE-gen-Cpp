#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/readme_examples.cpp" "tests/readme_examples.cpp"
mkdir -p "tests"
cp "/tests/readme_examples_noexceptions.cpp" "tests/readme_examples_noexceptions.cpp"

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
        # Compile readme_examples.cpp manually (not part of CMake targets)
        echo "Compiling readme_examples.cpp..."
        g++ -std=c++17 -o readme_examples tests/readme_examples.cpp -Iinclude -Isrc -Lbuild -lsimdjson 2>&1
        compile_status=$?

        if [ $compile_status -ne 0 ]; then
            echo "ERROR: readme_examples compilation failed"
            test_status=1
        else
            echo "SUCCESS: readme_examples compiled successfully"
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
