#!/bin/bash

cd /app/src

# Copy HEAD test file from /tests (overwrites BASE state)
cp "/tests/test_create_default_reporter.cc" "test/test_create_default_reporter.cc"

# Build the test that calls CreateDefaultDisplayReporter()
echo "Building test_create_default_reporter..."
if clang++ -std=c++11 -I/app/src/include -L/app/src/build/src -o /tmp/test_create_default_reporter test/test_create_default_reporter.cc -lbenchmark -lpthread > /tmp/build.log 2>&1; then
  echo "✓ test_create_default_reporter build succeeded"
else
  echo "✗ test_create_default_reporter build failed (this is expected if CreateDefaultDisplayReporter is not defined)"
  cat /tmp/build.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

# Run the test
echo "Running test_create_default_reporter..."
/tmp/test_create_default_reporter
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
