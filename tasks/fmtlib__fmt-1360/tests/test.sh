#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/core-test.cc" "test/core-test.cc"
cp "/tests/locale-test.cc" "test/locale-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild the specific tests
cd build
cmake ..
make core-test locale-test

# Run the specific tests (binaries are in bin/ directory)
./bin/core-test && ./bin/locale-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
