#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_dom_modify.cpp" "tests/test_dom_modify.cpp"

# Rebuild the test executable with the updated test file
# pugixml compiles all tests into a single executable (check when using cmake)
if ! make -j$(nproc); then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the test executable
# The test framework will run all tests including the updated dom_modify tests
./check
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
