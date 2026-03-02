#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "absl/debugging/internal"
cp "/tests/absl/debugging/internal/demangle_test.cc" "absl/debugging/internal/demangle_test.cc"

# Rebuild the specific tests after copying the new test files
cd build
cmake .. -DABSL_BUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
echo "=== Building test targets ==="
make absl_demangle_test -j$(nproc) 2>&1

# Run the specific test binary
echo "=== Running demangle_test ==="
./bin/absl_demangle_test 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
