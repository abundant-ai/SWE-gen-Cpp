#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/string_util_gtest.cc" "test/string_util_gtest.cc"

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
rm -f build/test/CMakeFiles/string_util_gtest.dir/string_util_gtest.cc.o
rm -f build/test/string_util_gtest

# Build the specific test executable for the modified test file
cmake --build build --config Debug --target string_util_gtest -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build string_util_gtest"
    test_status=1
fi

# Run the test only if it built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    echo "Running string_util_gtest..."
    ./test/string_util_gtest
    if [ $? -ne 0 ]; then
        echo "string_util_gtest FAILED"
        test_status=1
    else
        echo "string_util_gtest PASSED"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
