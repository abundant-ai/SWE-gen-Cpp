#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/core-test.cc" "test/core-test.cc"
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# This PR is about fixing conversion warnings when building with strict flags.
# The test: compile fmt library with -Wconversion -Werror, then build/run tests without strict flags
# BASE state: fmt library has buggy code → build with -Werror -Wconversion fails
# HEAD state: fmt library has fixed code → build succeeds

cd build
rm -rf *

# First pass: Build fmt library ONLY with strict warnings to verify it's clean
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=11 \
  -DFMT_TEST=OFF \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_FLAGS="-Wconversion -Werror"

make fmt
test_status=$?

# If fmt library builds cleanly, reconfigure and build/run tests normally
if [ $test_status -eq 0 ]; then
  rm -rf *
  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=11 \
    -DFMT_TEST=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++

  make core-test format-test
  if [ $? -eq 0 ]; then
    ./bin/core-test && ./bin/format-test
    test_status=$?
  else
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
