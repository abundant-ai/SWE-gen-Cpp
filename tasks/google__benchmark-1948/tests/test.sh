#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/basic_test.cc" "test/basic_test.cc"
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
mkdir -p "test"
cp "/tests/cxx11_test.cc" "test/cxx11_test.cc"
mkdir -p "test"
cp "/tests/donotoptimize_test.cc" "test/donotoptimize_test.cc"
mkdir -p "test"
cp "/tests/register_benchmark_test.cc" "test/register_benchmark_test.cc"

# Rebuild tests with the updated source files from /tests
cd build
if ! cmake --build . --config Debug -j 1; then
  echo "Build failed" >&2
  test_status=1
else
  # Run the specific tests for this PR
  ./test/basic_test && \
  ./test/benchmark_test && \
  ./test/cxx11_test && \
  ./test/donotoptimize_test && \
  ./test/register_benchmark_test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
