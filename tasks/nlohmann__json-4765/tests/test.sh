#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-bjdata.cpp" "tests/src/unit-bjdata.cpp"

# Build the test executable for unit-bjdata.cpp (creates test-bjdata_cpp11)
if ! cmake --build build --target test-bjdata_cpp11; then
    echo "Build failed for test-bjdata_cpp11"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable
./build/tests/test-bjdata_cpp11
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
