#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_parse.cpp" "tests/test_parse.cpp"

# Compile and run only the specific test files for this PR
# pugixml tests use a custom test framework - compile all test support files together
g++ -o test_runner \
    -std=c++17 \
    -I src \
    tests/main.cpp \
    tests/test.cpp \
    tests/allocator.cpp \
    tests/writer_string.cpp \
    tests/test_parse.cpp \
    src/pugixml.cpp

# Run the compiled test
./test_runner
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
