#!/bin/bash

cd /app/src

# First, check if the GCC workaround is present in benchmark.h (from PR #1340, prerequisite for #1410)
if grep -q "#if !defined(__GNUC__) || defined(__llvm__) || defined(__INTEL_COMPILER)" include/benchmark/benchmark.h; then
  echo "GCC workaround found in benchmark.h"
  gcc_workaround_present=1
else
  echo "FAIL: GCC workaround not found in benchmark.h"
  gcc_workaround_present=0
fi

# Copy the fixed AssemblyTests.cmake from /tests (to test PR #1410's compiler version warnings)
mkdir -p "test"
cp "/tests/AssemblyTests.cmake" "test/AssemblyTests.cmake"

# Clean and reconfigure to ensure fresh CMake configuration
rm -rf build/CMakeCache.txt build/CMakeFiles

# Reconfigure CMake to check if compiler version warning is emitted (PR #1410 feature)
cmake_output=$(cmake -B build -G Ninja \
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
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON 2>&1)

echo "$cmake_output"

# Check if the compiler version warning is emitted
if echo "$cmake_output" | grep -q "Unsupported.*version" && echo "$cmake_output" | grep -q "Assembly tests may be"; then
  echo "SUCCESS: Compiler version warning detected"
  warning_present=1
else
  echo "FAIL: Compiler version warning not found"
  warning_present=0
fi

# Test passes only if BOTH conditions are met (GCC workaround + compiler warnings)
if [ $gcc_workaround_present -eq 1 ] && [ $warning_present -eq 1 ]; then
  echo "PASS: Both GCC workaround and compiler version warnings present"
  test_status=0
else
  echo "FAIL: Missing required fixes"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
