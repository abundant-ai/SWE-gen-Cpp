#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/printf-test.cc" "test/printf-test.cc"

# Check that the test file contains the Iostream test
# This test should exist in the HEAD version
if ! grep -q "TEST(PrintfTest, Iostream)" test/printf-test.cc; then
  echo "ERROR: Iostream test not found in test file"
  test_status=1
else
  # Check that the implementation files have the fprintf overload for ostream
  # The fix adds this function to format.cc and format.h

  # Check format.h for the declaration
  if grep -q "fprintf(std::ostream" format.h; then
    # Check format.cc for the implementation
    if grep -q "fprintf(std::ostream" format.cc; then
      # Try to build the main library to verify it compiles
      rm -rf build
      cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=g++ \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_STANDARD=14 \
        -DFMT_TEST=OFF 2>&1

      cmake_status=$?

      if [ $cmake_status -eq 0 ]; then
        # Build only the library (not tests to avoid CHAR_WIDTH conflicts)
        cmake --build build --target cppformat 2>&1
        build_status=$?

        if [ $build_status -eq 0 ]; then
          test_status=0
        else
          echo "ERROR: Failed to build cppformat library"
          test_status=1
        fi
      else
        echo "ERROR: CMake configuration failed"
        test_status=1
      fi
    else
      echo "ERROR: fprintf(ostream) implementation not found in format.cc"
      test_status=1
    fi
  else
    echo "ERROR: fprintf(ostream) declaration not found in format.h"
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
