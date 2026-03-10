#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/compile-error-test"
cp "/tests/compile-error-test/CMakeLists.txt" "test/compile-error-test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"

# Reconfigure CMake to pick up the new test files with C++20
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_STANDARD=20

# Build the specific test using CMake
# In the buggy state, this should fail to compile because of the named argument issue
cmake --build . --target format-test
build_status=$?

if [ $build_status -ne 0 ]; then
  # Build failed - in buggy state, this is expected
  test_status=1
else
  # Build succeeded - run the tests
  ./bin/format-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
