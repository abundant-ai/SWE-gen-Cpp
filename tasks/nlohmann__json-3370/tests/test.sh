#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"

# Reconfigure CMake to pick up the updated test files
cmake -S . -B build -DJSON_BuildTests=ON -DJSON_MultipleHeaders=ON \
    -DCMAKE_CXX_FLAGS="-Wconversion -Werror"

# Rebuild the test target that includes the updated test file
cmake --build build --target test-regression2
build_status=$?

if [ $build_status -ne 0 ]; then
    echo "Build failed"
    test_status=1
else
    # Run the test executable
    echo "Running test-regression2..."
    ./build/test/test-regression2
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
