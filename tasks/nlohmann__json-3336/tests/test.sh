#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"
mkdir -p "test/src"
cp "/tests/src/fuzzer-parse_bjdata.cpp" "test/src/fuzzer-parse_bjdata.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-bjdata.cpp" "test/src/unit-bjdata.cpp"

# Reconfigure CMake to pick up the updated test files
cmake -S . -B build -DJSON_BuildTests=ON -DJSON_MultipleHeaders=ON \
    -DCMAKE_CXX_FLAGS="-Wconversion -Werror"

# Rebuild the test target that includes the updated test file
# Try test-bjdata first, fall back to test-bjdata_cpp11 if needed
if cmake --build build --target test-bjdata 2>/dev/null; then
    echo "Running test-bjdata..."
    ./build/test/test-bjdata
    test_status=$?
elif cmake --build build --target test-bjdata_cpp11; then
    echo "Running test-bjdata_cpp11..."
    ./build/test/test-bjdata_cpp11
    test_status=$?
else
    echo "Build failed"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
