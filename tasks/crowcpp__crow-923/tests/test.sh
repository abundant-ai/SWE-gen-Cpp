#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/template"
cp "/tests/template/crow_extra_mustache_tests.json" "tests/template/crow_extra_mustache_tests.json"
mkdir -p "tests/template"
cp "/tests/template/mustachetest.cpp" "tests/template/mustachetest.cpp"
mkdir -p "tests/template"
cp "/tests/template/test.py" "tests/template/test.py"

# Build the mustachetest executable from the updated test files
g++ -std=c++17 -I include tests/template/mustachetest.cpp -o tests/template/mustachetest
build_status=$?

# If build fails, tests fail
if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit $build_status
fi

# Run the Python test script which executes the mustachetest binary
# Add timeout to prevent infinite loops from buggy code
cd tests/template
timeout 30 python3 test.py
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
