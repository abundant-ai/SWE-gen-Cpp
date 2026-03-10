#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/parser_test.cpp" "test/parser_test.cpp"

# Rebuild the test binary with the updated test file
cd build
if ! make -j2 yaml-cpp-tests; then
  echo "ERROR: Failed to build tests with HEAD test file" >&2
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run only tests from ParserTest suite (from parser_test.cpp)
./test/yaml-cpp-tests --gtest_filter="ParserTest.*"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
