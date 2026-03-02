#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-bjdata.cpp" "tests/src/unit-bjdata.cpp"

# Rebuild and run the specific test binary with the updated test file
cmake --build build --target test-bjdata_cpp11
build_status=$?

if [ $build_status -ne 0 ]; then
    echo "Build failed"
    test_status=1
else
    # Run the test executable
    ./build/tests/test-bjdata_cpp11
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
