#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"
cp "/tests/src/unit-udt_macro.cpp" "test/src/unit-udt_macro.cpp"

# Rebuild the tests to incorporate the HEAD test files
cd build
cmake --build . --target test-regression
cmake --build . --target test-udt_macro

# Run the specific unit tests
ctest -R "test-regression|test-udt_macro" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
