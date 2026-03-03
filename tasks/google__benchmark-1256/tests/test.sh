#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"

# Initialize test_status
test_status=0

# Rebuild the output_test_helper library with the fixed file
cd /app/src
cmake --build build --config Debug --target output_test_helper -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build output_test_helper"
    test_status=1
fi

# Rebuild and run reporter_output_test which uses the output_test_helper
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target reporter_output_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build reporter_output_test"
        test_status=1
    fi
fi

# Run the test only if it built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build
    ./test/reporter_output_test
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
