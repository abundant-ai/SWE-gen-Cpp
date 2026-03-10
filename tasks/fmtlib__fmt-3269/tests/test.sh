#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Clean and reconfigure CMake to pick up the new test files and any library changes
rm -rf build/*
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DFMT_PEDANTIC=ON \
    -DCMAKE_CXX_FLAGS="-I/usr/local/include/workaround -stdlib=libc++ -DFMT_USE_BITINT=1"
test_status=$?

# Build the library first
if [ $test_status -eq 0 ]; then
  cmake --build . --target fmt
  test_status=$?
fi

# Build and run format-impl-test
if [ $test_status -eq 0 ]; then
  cmake --build . --target format-impl-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  ./bin/format-impl-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
