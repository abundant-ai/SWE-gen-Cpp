#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/compile-test.cc" "test/compile-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Reconfigure CMake to pick up the new test files
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DFMT_PEDANTIC=ON \
    -DCMAKE_CXX_FLAGS="-I/usr/local/include/workaround -stdlib=libc++"

# Build the specific test target
cmake --build . --target compile-test
test_status=$?

if [ $test_status -eq 0 ]; then
  # Run the specific test
  ./bin/compile-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
