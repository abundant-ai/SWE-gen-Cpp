#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/compile-test.cc" "test/compile-test.cc"

test_status=0

# Reconfigure CMake after copying new test files
echo "Reconfiguring CMake..."
cd build
if ! cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    # Build the specific test file
    echo "Building compile-test..."
    if ! cmake --build . --target compile-test 2>&1; then
        echo "FAIL: compile-test build failed"
        test_status=1
    else
        echo "PASS: compile-test built successfully"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
