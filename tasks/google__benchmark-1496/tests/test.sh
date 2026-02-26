#!/bin/bash

cd /app/src

# Remove python symlink to simulate a system where only python3 exists
# This is the key scenario the fix addresses
rm -f /usr/bin/python

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/AssemblyTests.cmake" "test/AssemblyTests.cmake"

# Reconfigure CMake to pick up the updated AssemblyTests.cmake
# This is critical because AssemblyTests.cmake is included during configuration
echo "Reconfiguring CMake to apply AssemblyTests.cmake changes..."
if cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_ASSEMBLY_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON > /tmp/cmake.log 2>&1; then
  echo "✓ CMake configuration succeeded"
else
  echo "✗ CMake configuration failed"
  cat /tmp/cmake.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

# Rebuild to verify the fix works with Python3 properly detected
echo "Building to verify Python3 requirement works..."
if cmake --build build --config Debug -j 1 > /tmp/build.log 2>&1; then
  echo "✓ Build succeeded - Python3 was properly found and used"
  test_status=0
else
  echo "✗ Build failed"
  cat /tmp/build.log | tail -50
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
