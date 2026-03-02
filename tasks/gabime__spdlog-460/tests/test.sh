#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/cond_logging.cpp" "tests/cond_logging.cpp"
mkdir -p "tests"
cp "/tests/tests.vcxproj" "tests/tests.vcxproj"
mkdir -p "tests"
cp "/tests/tests.vcxproj.filters" "tests/tests.vcxproj.filters"

# Build and run tests using the Makefile
cd /app/src/tests
make rebuild 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run the tests binary
./tests
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
