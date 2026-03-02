#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/ranges-test.cc" "test/ranges-test.cc"

# Reconfigure CMake with updated test files
cmake -S . -B build \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON

# Build the project and the specific test executable
if ! cmake --build build --target ranges-test 2>&1; then
    echo "FAIL: Build failed"
    test_status=1
else
    # Run the specific test executable
    if ./build/bin/ranges-test; then
        echo "PASS: All tests passed"
        test_status=0
    else
        echo "FAIL: Tests failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
