#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

test_status=0

# Reconfigure CMake with FMT_ENFORCE_COMPILE_STRING to test if library compiles
echo "Reconfiguring CMake with FMT_ENFORCE_COMPILE_STRING..."
cd build
if ! cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=OFF \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_CXX_FLAGS="-DFMT_ENFORCE_COMPILE_STRING" 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    test_status=1
fi

# Try to build the library with FMT_ENFORCE_COMPILE_STRING
# This will fail in buggy state because internal format calls don't use FMT_STRING
if [ $test_status -eq 0 ]; then
    echo "Building fmt library with FMT_ENFORCE_COMPILE_STRING..."
    if ! cmake --build . --target fmt 2>&1; then
        echo "FAIL: fmt library build failed with FMT_ENFORCE_COMPILE_STRING"
        test_status=1
    else
        echo "PASS: fmt library builds successfully with FMT_ENFORCE_COMPILE_STRING"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
