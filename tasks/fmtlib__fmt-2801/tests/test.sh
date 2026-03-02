#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/posix-mock-test.cc" "test/posix-mock-test.cc"
mkdir -p "test"
cp "/tests/test-main.cc" "test/test-main.cc"

cd build

test_status=0

# First, try to build the fmt library with strict -Wreserved-identifier warning
# This will fail if the code uses reserved identifiers like _Unchecked_type
echo "Building fmt library with -Wreserved-identifier..."
if ! cmake .. -DFMT_TEST=OFF \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_CXX_FLAGS="-Werror -Wreserved-identifier" 2>&1 || \
   ! make fmt 2>&1; then
    echo "FAIL: fmt library build failed with -Wreserved-identifier"
    test_status=1
else
    echo "PASS: fmt library built successfully with -Wreserved-identifier"

    # Reconfigure for tests (without strict warning since gtest has reserved identifiers)
    # Explicitly clear CMAKE_CXX_FLAGS to avoid carrying over -Wreserved-identifier
    cmake .. -DFMT_TEST=ON \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_CXX_FLAGS="" 2>&1

    # Build and run the specific tests
    if ! make posix-mock-test 2>&1; then
        echo "FAIL: posix-mock-test build failed"
        test_status=1
    elif ! ./bin/posix-mock-test; then
        echo "FAIL: posix-mock-test failed"
        test_status=1
    else
        echo "PASS: posix-mock-test passed"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
