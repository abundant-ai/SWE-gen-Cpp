#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/options_test.cc" "test/options_test.cc"
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"

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
rm -f build/test/CMakeFiles/options_test.dir/options_test.cc.o
rm -f build/test/options_test
rm -f build/test/CMakeFiles/output_test_helper.dir/output_test_helper.cc.o
rm -f build/test/liboutput_test_helper.a
rm -f build/test/CMakeFiles/reporter_output_test.dir/reporter_output_test.cc.o
rm -f build/test/reporter_output_test

# Build the specific test executables and library for the modified test files
# Note: output_test_helper is a library, not a test executable
cmake --build build --config Debug --target options_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build options_test"
    test_status=1
fi

cmake --build build --config Debug --target output_test_helper -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build output_test_helper library"
    test_status=1
fi

cmake --build build --config Debug --target reporter_output_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build reporter_output_test"
    test_status=1
fi

# Run the tests only if they built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    echo "Running options_test..."
    ./test/options_test
    if [ $? -ne 0 ]; then
        echo "options_test FAILED"
        test_status=1
    else
        echo "options_test PASSED"
    fi

    echo "Running reporter_output_test..."
    ./test/reporter_output_test
    if [ $? -ne 0 ]; then
        echo "reporter_output_test FAILED"
        test_status=1
    else
        echo "reporter_output_test PASSED"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
