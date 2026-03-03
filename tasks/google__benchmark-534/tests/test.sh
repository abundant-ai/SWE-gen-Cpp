#!/bin/bash

cd /app/src

# Initialize test_status
test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"

# Fix missing #include <limits> in benchmark_register.h if it exists
# The fix.patch creates this file but is missing the include
if [ -f "src/benchmark_register.h" ]; then
    if ! grep -q "#include <limits>" "src/benchmark_register.h"; then
        sed -i '/#include <vector>/a #include <limits>' "src/benchmark_register.h"
    fi
fi

# Rebuild tests with the updated test files
cmake --build build --config Debug -j 1

# Run the specific test executable that corresponds to the modified test file
build/test/reporter_output_test

test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
