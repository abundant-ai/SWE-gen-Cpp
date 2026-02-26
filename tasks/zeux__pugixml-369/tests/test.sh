#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_xpath_parse.cpp" "tests/test_xpath_parse.cpp"

# Rebuild the test executable with the updated test file
# pugixml compiles all tests into a single executable (pugixml-check when using cmake)
make -j$(nproc)

# Run the test executable
# The test framework will run all tests including the updated xpath_parse tests
./pugixml-check
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
