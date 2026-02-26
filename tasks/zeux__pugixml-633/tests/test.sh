#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_dom_modify.cpp" "tests/test_dom_modify.cpp"
cp "/tests/test_dom_text.cpp" "tests/test_dom_text.cpp"

# Compile and run only the specific test files for this PR
# pugixml tests use a custom test framework - compile all test support files together
# Enable PUGIXML_STRING_VIEW and manually define PUGIXML_HAS_STRING_VIEW to test string_view functionality
# In the buggy state, PUGIXML_HAS_STRING_VIEW won't be auto-defined, so we define it manually
# This allows the string_view tests to run and fail (compilation error due to missing functions)
g++ -o test_runner \
    -std=c++17 \
    -DPUGIXML_STRING_VIEW \
    -DPUGIXML_HAS_STRING_VIEW \
    -I src \
    tests/main.cpp \
    tests/test.cpp \
    tests/allocator.cpp \
    tests/writer_string.cpp \
    tests/test_dom_modify.cpp \
    tests/test_dom_text.cpp \
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
