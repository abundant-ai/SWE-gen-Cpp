#!/bin/bash

cd /app/src

# Remove conflicting test/format file that interferes with compilation
rm -f test/format

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/enforce-compile-string-test.cc" "test/enforce-compile-string-test.cc"
mkdir -p "test"
cp "/tests/ranges-test.cc" "test/ranges-test.cc"

# Build the specific test targets using CMake
cmake --build build --target ranges-test
cmake --build build --target enforce-compile-string-test

# Run the test executables
./build/bin/ranges-test
ranges_status=$?

./build/bin/enforce-compile-string-test
enforce_status=$?

# Both tests must pass
if [ $ranges_status -eq 0 ] && [ $enforce_status -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
