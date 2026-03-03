#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/args_product_test.cc" "test/args_product_test.cc"

# Initialize test_status
test_status=0

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Remove old test object files to force rebuild with new test files
rm -f build/test/CMakeFiles/args_product_test.dir/args_product_test.cc.o
rm -f build/test/args_product_test

# Build the specific test executable for the modified test file
cmake --build build --config Debug --target args_product_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build args_product_test"
    test_status=1
fi

# Run the test only if it built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    echo "Running args_product_test..."
    ./test/args_product_test
    if [ $? -ne 0 ]; then
        echo "args_product_test FAILED"
        test_status=1
    else
        echo "args_product_test PASSED"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
