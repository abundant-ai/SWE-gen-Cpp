#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"

# Rebuild the specific test target with updated source file
# Exit immediately if build fails
if ! cmake --build build --target benchmark_test -j 1; then
    echo "Build failed - tests cannot be run" >&2
    test_status=1
else
    # Run only the specific test for this PR
    cd build
    ctest -R "^benchmark_test$" --output-on-failure -V
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
