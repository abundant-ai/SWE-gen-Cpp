#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/ostream-test.cc" "test/ostream-test.cc"
mkdir -p "test"
cp "/tests/xchar-test.cc" "test/xchar-test.cc"

# Clean and reconfigure CMake to pick up the new test files and any library changes
rm -rf build/*
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON
test_status=$?

# Build the library first
if [ $test_status -eq 0 ]; then
  cmake --build . --target fmt
  test_status=$?
fi

# Build and run format-test
if [ $test_status -eq 0 ]; then
  cmake --build . --target format-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  ./bin/format-test
  test_status=$?
fi

# Build and run ostream-test
if [ $test_status -eq 0 ]; then
  cmake --build . --target ostream-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  ./bin/ostream-test
  test_status=$?
fi

# Build and run xchar-test
if [ $test_status -eq 0 ]; then
  cmake --build . --target xchar-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  ./bin/xchar-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
