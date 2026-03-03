#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"

# Initialize test_status
test_status=0

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

# Reconfigure CMake to pick up the updated test/CMakeLists.txt
cd /app/src
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
if [ $? -ne 0 ]; then
    echo "Failed to reconfigure CMake"
    test_status=1
fi

# Build one test target to verify the benchmark::benchmark alias works
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target benchmark_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build benchmark_test (testing benchmark::benchmark alias)"
        test_status=1
    fi
fi

# Build one test target with main to verify the benchmark::benchmark_main alias works
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target skip_with_error_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build skip_with_error_test (testing benchmark::benchmark_main alias)"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
