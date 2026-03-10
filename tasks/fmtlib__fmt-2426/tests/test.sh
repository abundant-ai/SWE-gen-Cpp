#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/compile-fp-test.cc" "test/compile-fp-test.cc"

# Reconfigure CMake to pick up updated test files
cd build
cmake ..
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
  echo "Failed to reconfigure CMake" >&2
  test_status=1
else
  # Build the specific test
  cmake --build . --target compile-fp-test
  build_status=$?

  if [ $build_status -ne 0 ]; then
    echo "Failed to build compile-fp-test" >&2
    test_status=1
  else
    # Run the test executable
    ./bin/compile-fp-test
    test_status=$?
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
