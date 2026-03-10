#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/compile-test.cc" "test/compile-test.cc"

# Reconfigure CMake to pick up updated test files
cd build
cmake ..
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
  echo "Failed to reconfigure CMake" >&2
  test_status=1
else
  # Build and run the compile-test executable
  cmake --build . --target compile-test
  build_status=$?

  if [ $build_status -ne 0 ]; then
    echo "Failed to build compile-test" >&2
    test_status=1
  else
    # Run the test executable (located in build/bin directory)
    bin/compile-test
    test_status=$?
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
