#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
cp "/tests/detect-stdfs.cc" "test/detect-stdfs.cc"

# Reconfigure CMake with updated test files
cd build && cmake .. \
    -DCMAKE_C_COMPILER=gcc-8 \
    -DCMAKE_CXX_COMPILER=g++-8 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DFMT_TEST=ON && cd ..

# Build the project and the specific test executable
cd build
if ! make std-test 2>&1; then
    echo "FAIL: Build failed"
    test_status=1
else
    # Run the specific test executable
    if ./bin/std-test; then
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
