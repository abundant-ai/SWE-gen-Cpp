#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "absl/strings"
cp "/tests/absl/strings/escaping_test.cc" "absl/strings/escaping_test.cc"

# Rebuild the specific test after copying the new test file
cd build
cmake .. -DABSL_BUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
echo "=== Building test target ==="
make absl_escaping_test -j$(nproc) 2>&1

# Run the specific test binary
echo "=== Running test ==="
./bin/absl_escaping_test 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
