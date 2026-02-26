#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/compile-test"
cp "/tests/compile-test/CMakeLists.txt" "test/compile-test/CMakeLists.txt"

# Clean build directory to avoid CMake cache issues
rm -rf build

# Reconfigure with the updated test files (enable pedantic to trigger compile-test)
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=14 \
    -DFMT_TEST=ON \
    -DFMT_PEDANTIC=ON 2>&1

cmake_status=$?

if [ $cmake_status -ne 0 ]; then
  test_status=1
else
  # Build only the fmt library (not the tests which have warnings)
  cmake --build build --target fmt --parallel $(nproc) 2>&1
  build_status=$?

  if [ $build_status -ne 0 ]; then
    test_status=1
  else
    # Run the compile-test suite via CTest
    cd build && ctest -R compile-test --output-on-failure
    test_status=$?
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
