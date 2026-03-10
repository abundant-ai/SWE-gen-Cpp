#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/static-export-test"
cp "/tests/static-export-test/CMakeLists.txt" "test/static-export-test/CMakeLists.txt"
mkdir -p "test/static-export-test"
cp "/tests/static-export-test/library.cc" "test/static-export-test/library.cc"
mkdir -p "test/static-export-test"
cp "/tests/static-export-test/main.cc" "test/static-export-test/main.cc"

# Reconfigure CMake to pick up updated test files
cd build
cmake ..
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
  echo "Failed to reconfigure CMake" >&2
  test_status=1
else
  # Build the static-export-test subdirectory as a separate CMake project
  mkdir -p static-export-test
  cd static-export-test

  cmake ../../test/static-export-test \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_BUILD_TYPE=Release

  cmake_sub_status=$?

  if [ $cmake_sub_status -ne 0 ]; then
    echo "Failed to configure static-export-test" >&2
    test_status=1
  else
    cmake --build .
    build_status=$?

    if [ $build_status -ne 0 ]; then
      echo "Failed to build static-export-test" >&2
      test_status=1
    else
      # Run the executable
      ./exe-test
      test_status=$?
    fi
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
