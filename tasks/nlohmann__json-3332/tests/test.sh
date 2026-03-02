#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-class_iterator.cpp" "test/src/unit-class_iterator.cpp"

# Reconfigure CMake to pick up the updated test files
cmake -S . -B build -DJSON_BuildTests=ON -DJSON_MultipleHeaders=ON \
    -DCMAKE_CXX_FLAGS="-Wconversion -Werror"

# Rebuild the test target that includes the updated test file
# Try test-class_iterator first, fall back to test-class_iterator_cpp11 if needed
if cmake --build build --target test-class_iterator 2>/dev/null; then
    echo "Running test-class_iterator..."
    ./build/test/test-class_iterator
    test_status=$?
elif cmake --build build --target test-class_iterator_cpp11; then
    echo "Running test-class_iterator_cpp11..."
    ./build/test/test-class_iterator_cpp11
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
