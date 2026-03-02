#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"

# Reconfigure CMake to force FMT_USE_BITINT=1 (ensures bitint tests always compile)
cmake -S . -B build \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON \
    -DCMAKE_CXX_FLAGS="-DFMT_USE_BITINT=1"

# Rebuild and run the specific test target after copying updated test file
cmake --build build --target format-impl-test && build/bin/format-impl-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
