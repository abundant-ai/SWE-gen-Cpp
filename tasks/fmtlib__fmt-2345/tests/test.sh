#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/chrono-test.cc" "test/chrono-test.cc"
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
  # Build and run chrono-test
  cmake --build . --target chrono-test
  build_status_1=$?

  if [ $build_status_1 -ne 0 ]; then
    echo "Failed to build chrono-test" >&2
    test_status=1
  else
    ./bin/chrono-test
    test_status_1=$?

    if [ $test_status_1 -ne 0 ]; then
      echo "chrono-test failed" >&2
      test_status=1
    else
      # Build and run compile-test
      cmake --build . --target compile-test
      build_status_2=$?

      if [ $build_status_2 -ne 0 ]; then
        echo "Failed to build compile-test" >&2
        test_status=1
      else
        ./bin/compile-test
        test_status=$?
      fi
    fi
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
