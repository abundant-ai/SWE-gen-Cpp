#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/add-subdirectory-test"
cp "/tests/add-subdirectory-test/CMakeLists.txt" "test/add-subdirectory-test/CMakeLists.txt"
mkdir -p "test/compile-error-test"
cp "/tests/compile-error-test/CMakeLists.txt" "test/compile-error-test/CMakeLists.txt"
mkdir -p "test/find-package-test"
cp "/tests/find-package-test/CMakeLists.txt" "test/find-package-test/CMakeLists.txt"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/CMakeLists.txt" "test/fuzzing/CMakeLists.txt"
mkdir -p "test/gtest"
cp "/tests/gtest/CMakeLists.txt" "test/gtest/CMakeLists.txt"
mkdir -p "test/static-export-test"
cp "/tests/static-export-test/CMakeLists.txt" "test/static-export-test/CMakeLists.txt"

# Clean and reconfigure CMake to pick up the new CMakeLists.txt changes
rm -rf build/*
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON 2>&1 | tee cmake_output.log
test_status=${PIPESTATUS[0]}

# Verify the new CMake approach is being used (should NOT use cxx14.cmake)
if [ $test_status -eq 0 ]; then
  if grep -q "include(cxx14)" ../CMakeLists.txt 2>/dev/null; then
    echo "ERROR: Old cxx14.cmake approach still being used!" >&2
    test_status=1
  fi
fi

# Verify that cmake_minimum_required is 3.8 or higher
if [ $test_status -eq 0 ]; then
  if ! grep -q "cmake_minimum_required(VERSION 3.8" ../CMakeLists.txt 2>/dev/null; then
    echo "ERROR: CMake minimum version should be 3.8!" >&2
    test_status=1
  fi
fi

# Build the fmt library to verify target_compile_features works
if [ $test_status -eq 0 ]; then
  cmake --build . --target fmt
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
