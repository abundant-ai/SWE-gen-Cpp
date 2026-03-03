#!/bin/bash

cd /app/src

test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"

# Rebuild the specific tests affected by the changes
if ! cmake --build build --config Debug -j 1; then
    echo "Build failed after applying HEAD test files" >&2
    test_status=1
else
    # Run the specific test binary for reporter_output_test
    ./build/test/reporter_output_test
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
