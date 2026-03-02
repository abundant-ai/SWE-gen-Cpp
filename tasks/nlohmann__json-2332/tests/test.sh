#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-class_lexer.cpp" "test/src/unit-class_lexer.cpp"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"

# Rebuild the tests to incorporate the HEAD test files
cd build
cmake --build . --target test-class_lexer test-regression2

# Run the specific unit tests
ctest -R "test-class_lexer|test-regression2" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
