#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"
mkdir -p "test"
cp "/tests/gtest-extra-test.cc" "test/gtest-extra-test.cc"

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=11 \
    -DFMT_TEST=ON 2>&1

# Build the specific test targets (capture both stdout and stderr)
cmake --build build --target format-impl-test --parallel $(nproc) 2>&1
build_status1=$?

cmake --build build --target gtest-extra-test --parallel $(nproc) 2>&1
build_status2=$?

# If either build failed, exit with error
if [ $build_status1 -ne 0 ] || [ $build_status2 -ne 0 ]; then
  echo "Build failed"
  test_status=1
else
  # Run both tests
  ./build/bin/format-impl-test
  test_status1=$?

  ./build/bin/gtest-extra-test
  test_status2=$?

  # Test passes only if both pass
  if [ $test_status1 -eq 0 ] && [ $test_status2 -eq 0 ]; then
    test_status=0
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
