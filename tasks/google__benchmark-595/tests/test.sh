#!/bin/bash

cd /app/src

# Copy fixed AssemblyTests.cmake from /tests (this is part of the fix)
mkdir -p "test"
cp "/tests/AssemblyTests.cmake" "test/AssemblyTests.cmake"

# Initialize test_status
test_status=0

# Test whether the split_list fix allows CMake to configure properly
# The bug occurs when BENCHMARK_ENABLE_GTEST_TESTS=OFF but BENCHMARK_ENABLE_ASSEMBLY_TESTS=ON
# Without the fix:
#   - cmake/split_list.cmake doesn't exist (removed by bug.patch, restored by fix.patch)
#   - test/AssemblyTests.cmake has include(split_list) (copied from /tests)
#   - Configuration fails because split_list.cmake is not found
# With the fix:
#   - cmake/split_list.cmake exists (created by fix.patch)
#   - test/AssemblyTests.cmake has include(split_list) (copied from /tests)
#   - Configuration succeeds
rm -rf build
cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=OFF \
    -DBENCHMARK_ENABLE_ASSEMBLY_TESTS=ON \
    -DLLVM_FILECHECK_EXE=/usr/bin/FileCheck-18 \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

if [ $? -ne 0 ]; then
    echo "Failed to configure project with assembly tests enabled and gtest tests disabled"
    test_status=1
else
    echo "CMake configuration succeeded with GTEST_TESTS=OFF and ASSEMBLY_TESTS=ON"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
