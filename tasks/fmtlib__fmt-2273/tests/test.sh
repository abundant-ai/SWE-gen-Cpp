#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/gtest-extra-test.cc" "test/gtest-extra-test.cc"
mkdir -p "test"
cp "/tests/os-test.cc" "test/os-test.cc"
mkdir -p "test"
cp "/tests/posix-mock-test.cc" "test/posix-mock-test.cc"

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

# Build and run gtest-extra-test
if [ $test_status -eq 0 ]; then
    echo "Building gtest-extra-test..."
    if ! cmake --build . --target gtest-extra-test 2>&1; then
        echo "FAIL: gtest-extra-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running gtest-extra-test..."
    if ! ./bin/gtest-extra-test 2>&1; then
        echo "FAIL: gtest-extra-test execution failed"
        test_status=1
    else
        echo "PASS: gtest-extra-test passed"
    fi
fi

# Build and run os-test
if [ $test_status -eq 0 ]; then
    echo "Building os-test..."
    if ! cmake --build . --target os-test 2>&1; then
        echo "FAIL: os-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running os-test..."
    if ! ./bin/os-test 2>&1; then
        echo "FAIL: os-test execution failed"
        test_status=1
    else
        echo "PASS: os-test passed"
    fi
fi

# Build and run posix-mock-test
if [ $test_status -eq 0 ]; then
    echo "Building posix-mock-test..."
    if ! cmake --build . --target posix-mock-test 2>&1; then
        echo "FAIL: posix-mock-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running posix-mock-test..."
    if ! ./bin/posix-mock-test 2>&1; then
        echo "FAIL: posix-mock-test execution failed"
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
