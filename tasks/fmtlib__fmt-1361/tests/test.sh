#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"
mkdir -p "test"
cp "/tests/grisu-test.cc" "test/grisu-test.cc"

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON

# Build the specific test targets
cmake --build build --target format-impl-test --parallel $(nproc)
cmake --build build --target grisu-test --parallel $(nproc)

# Run the tests
./build/bin/format-impl-test
format_impl_status=$?

./build/bin/grisu-test
grisu_status=$?

# Check if both tests passed
if [ $format_impl_status -eq 0 ] && [ $grisu_status -eq 0 ]; then
  test_status=0
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
