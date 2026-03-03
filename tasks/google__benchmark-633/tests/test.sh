#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"

# Initialize test_status
test_status=0

# Reconfigure CMake after copying test files to pick up any changes
cd /app/src
rm -rf build/CMakeCache.txt build/CMakeFiles
cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_ASSEMBLY_TESTS=ON \
    -DLLVM_FILECHECK_EXE=/usr/bin/FileCheck-18 \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Rebuild benchmark_main library to pick up changes
cmake --build build --config Debug --target benchmark_main -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark_main library"
    test_status=1
fi

# Build and run reporter_output_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target reporter_output_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build reporter_output_test"
        test_status=1
    else
        ./build/test/reporter_output_test --benchmark_min_time=0.01
        if [ $? -ne 0 ]; then
            echo "reporter_output_test failed"
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
