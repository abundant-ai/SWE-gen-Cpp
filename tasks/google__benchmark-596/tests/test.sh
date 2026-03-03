#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/string_util_gtest.cc" "test/string_util_gtest.cc"

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

# Build complexity_test target
cmake --build build --config Debug --target complexity_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build complexity_test"
    test_status=1
fi

# Build string_util_gtest target
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target string_util_gtest -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build string_util_gtest"
        test_status=1
    fi
fi

# Run the tests
if [ $test_status -eq 0 ]; then
    cd /app/src
    ./build/test/complexity_test --benchmark_min_time=0.01
    if [ $? -ne 0 ]; then
        echo "complexity_test failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    cd /app/src
    ./build/test/string_util_gtest
    if [ $? -ne 0 ]; then
        echo "string_util_gtest failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
