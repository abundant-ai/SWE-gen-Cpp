#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"

# Rebuild and run the specific test binary with the updated test file
# Use cpp17 version to test C++17-specific features (std::any)
cmake --build build --target test-regression2_cpp17
build_status=$?

if [ $build_status -ne 0 ]; then
    echo "Build failed"
    test_status=1
else
    # Run the test executable
    ./build/test/test-regression2_cpp17
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
