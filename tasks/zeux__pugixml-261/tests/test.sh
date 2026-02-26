#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_xpath.cpp" "tests/test_xpath.cpp"
mkdir -p "tests"
cp "/tests/test_xpath_operators.cpp" "tests/test_xpath_operators.cpp"

# Rebuild the test suite with the updated test files
rm -rf CMakeCache.txt CMakeFiles check
cmake . -DBUILD_TESTS=ON && make -j$(nproc)

# Run the test executable with filter for xpath tests
./check --test=*xpath*
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
