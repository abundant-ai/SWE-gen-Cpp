#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"

# Rebuild the specific test executable after copying the updated test file
# Use C++20 version because the ambiguity bug is observed with C++20
if ! cmake --build build --target test-regression2_cpp20 --parallel $(nproc); then
    # Compilation failed - this is expected for the buggy code
    echo "Compilation failed (expected for buggy code)"
    test_status=1
else
    # Compilation succeeded - run the test
    ./build/tests/test-regression2_cpp20
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
