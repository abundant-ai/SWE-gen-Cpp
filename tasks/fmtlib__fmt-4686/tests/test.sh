#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/xchar-test.cc" "test/xchar-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Build the specific test target
cd build
cmake --build . --target xchar-test
test_status=$?

if [ $test_status -eq 0 ]; then
  # Run the specific test
  ./bin/xchar-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
