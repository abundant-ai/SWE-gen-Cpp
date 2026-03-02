#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/ostream-test.cc" "test/ostream-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild the specific test
cd build
cmake ..
make ostream-test

# Run the specific test (binary is in bin/ directory)
./bin/ostream-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
