#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/ostream-test.cc" "test/ostream-test.cc"

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=11 \
    -DFMT_TEST=ON 2>&1

# Build the specific test target (capture both stdout and stderr)
cmake --build build --target ostream-test --parallel $(nproc) 2>&1
build_status=$?

# If build failed, exit with error
if [ $build_status -ne 0 ]; then
  echo "Build failed"
  test_status=1
else
  # Run the test
  ./build/bin/ostream-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
