#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"

# Rebuild the test with the updated code (from /tests)
cd build
if ! cmake --build . --target test-regression2_cpp17; then
    echo "Build failed for test-regression2_cpp17"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable
cd tests
./test-regression2_cpp17
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
