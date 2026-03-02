#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild and run the compile tests (relevant to this PR)
cd build
rm -rf *

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DFMT_TEST=ON \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DFMT_PEDANTIC=ON

if [ $? -ne 0 ]; then
  test_status=1
else
  # Build the library
  make cppformat
  if [ $? -ne 0 ]; then
    test_status=1
  else
    # Check if the CMake package config files were generated
    # The fix should generate these files; the buggy version doesn't
    if [ -f "cppformatConfig.cmake" ] && [ -f "cppformatConfigVersion.cmake" ]; then
      test_status=0
    else
      echo "ERROR: CMake package config files not generated"
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
