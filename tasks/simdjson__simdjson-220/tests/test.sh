#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/pointercheck.cpp" "tests/pointercheck.cpp"

# Build the project with CMake
echo "Configuring with CMake..."
rm -rf build_test
cmake -DCMAKE_BUILD_TYPE=Debug -B build_test > /dev/null 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    echo "Building tests..."
    cmake --build build_test --target pointercheck -j=2 > /dev/null 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "ERROR: Build failed"
        test_status=1
    else
        echo "Running pointercheck..."
        ./build_test/tests/pointercheck
        test_status=$?
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
