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

# Test: Reconfigure with updated CMakeLists.txt files
# In buggy state: cxx14.cmake exists and prints "CXX_STANDARD:" and "Required features: cxx_variadic_templates"
# In fixed state: cxx14.cmake doesn't exist, uses target_compile_features, no such messages
cmake_output=$(cmake -S . -B build \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON 2>&1)

# Check that buggy cxx14.cmake messages are NOT present (indicates fix is applied)
if echo "$cmake_output" | grep -q "Required features: cxx_variadic_templates"; then
    echo "FAIL: Found 'Required features: cxx_variadic_templates' - buggy cxx14.cmake is active"
    test_status=1
elif ! cmake --build build > /dev/null 2>&1; then
    echo "FAIL: Build failed"
    test_status=1
else
    echo "PASS: CMake configuration uses target_compile_features correctly"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
