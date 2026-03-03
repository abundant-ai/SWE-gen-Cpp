#!/bin/bash

cd /app/src

test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/basic_test.cc" "test/basic_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

# Rebuild the specific tests affected by the changes
if ! cmake --build build --config Debug -j 1; then
    echo "Build failed after applying HEAD test files" >&2
    test_status=1
else
    # Run the specific test binaries for basic_test and skip_with_error_test
    ./build/test/basic_test
    if [ $? -ne 0 ]; then
        test_status=1
    fi

    ./build/test/skip_with_error_test
    if [ $? -ne 0 ]; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
