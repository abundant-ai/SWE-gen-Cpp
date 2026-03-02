#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/printf-test.cc" "test/printf-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild and run the printf-test
cd build
rm -rf *

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DFMT_TEST=ON \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DFMT_PEDANTIC=ON \
  -DCMAKE_CXX_FLAGS="-I/usr/local/include/workaround" 2>&1

if [ $? -ne 0 ]; then
  echo "CMake configuration failed"
  test_status=1
else
  # Build and run the printf-test
  timeout 60 make printf-test 2>&1
  make_status=$?
  if [ $make_status -eq 124 ]; then
    echo "Build timed out"
    test_status=1
  elif [ $make_status -ne 0 ]; then
    echo "Build failed with status $make_status"
    test_status=1
  else
    ./bin/printf-test 2>&1
    test_status=$?
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
