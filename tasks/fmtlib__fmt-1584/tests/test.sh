#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/format-dyn-args-test.cc" "test/format-dyn-args-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild the specific test
cd build
cmake ..
make format-dyn-args-test

# Run the specific test (binary is in bin/ directory)
./bin/format-dyn-args-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
