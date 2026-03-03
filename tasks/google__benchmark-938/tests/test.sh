#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

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
rm -f build/test/CMakeFiles/skip_with_error_test.dir/skip_with_error_test.cc.o
rm -f build/test/skip_with_error_test

# Build the specific test executable for the modified test file
cmake --build build --config Debug --target skip_with_error_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build skip_with_error_test"
    test_status=1
fi

# Run the test only if it built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    echo "Running skip_with_error_test..."
    ./test/skip_with_error_test
    if [ $? -ne 0 ]; then
        echo "skip_with_error_test FAILED"
        test_status=1
    else
        echo "skip_with_error_test PASSED"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
