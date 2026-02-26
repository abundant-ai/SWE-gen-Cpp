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

# Clean build directory to force full reconfiguration with updated test files
rm -rf build

# The fix removes support/cmake/cxx14.cmake and switches to target_compile_features
# Check if the fix has been applied by verifying cxx14.cmake is removed
if [ -f "support/cmake/cxx14.cmake" ]; then
  # BASE state - fix NOT applied
  echo "FAIL: cxx14.cmake still exists - fix not applied"
  test_status=1
else
  # HEAD state - fix applied
  # Reconfigure and verify it works with the new approach
  cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_STANDARD=11 \
      -DFMT_TEST=ON
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
