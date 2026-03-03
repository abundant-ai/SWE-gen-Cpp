#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/spec_arg_test.cc" "test/spec_arg_test.cc"

# Initialize test_status
test_status=0

# Rebuild the spec_arg_test with the fixed file
cd /app/src
cmake --build build --config Debug --target spec_arg_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build spec_arg_test"
    test_status=1
fi

# Run the test only if it built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build
    ./test/spec_arg_test --benchmark_filter=BM_NotChosen
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
