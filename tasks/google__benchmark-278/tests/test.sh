#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/cxx03_test.cc" "test/cxx03_test.cc"
cp "/tests/multiple_ranges_test.cc" "test/multiple_ranges_test.cc"

# Rebuild the specific test targets with updated source files
# Exit immediately if build fails
if ! cmake --build build --target cxx03_test multiple_ranges_test -j 1; then
    echo "Build failed - tests cannot be run" >&2
    test_status=1
else
    # Run only the specific tests for this PR
    cd build
    ctest -R "^(cxx03|multiple_ranges_test)$" --output-on-failure -V
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
