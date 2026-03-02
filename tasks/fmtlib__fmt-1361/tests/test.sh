#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"
cp "/tests/grisu-test.cc" "test/grisu-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild the specific tests
cd build
cmake ..
make format-impl-test grisu-test

# Run the specific tests (binaries are in bin/ directory)
./bin/format-impl-test && ./bin/grisu-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
