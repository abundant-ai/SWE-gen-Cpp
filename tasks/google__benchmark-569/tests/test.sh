#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"

# Initialize test_status
test_status=0

# The bug is a compilation error: BigOFunc typedef uses int instead of int64_t,
# causing type mismatch errors when the test file uses int64_t in lambda complexity functions.
# Test if the code can be rebuilt successfully with the fixed test file.

# Clean the old complexity_test build artifacts to force a rebuild
rm -f build/test/complexity_test
rm -f build/test/CMakeFiles/complexity_test.dir/complexity_test.cc.o

# Try to rebuild just the complexity_test executable
if cmake --build build --config Debug --target complexity_test -j 1; then
    # Build succeeded - now run the test to verify it works correctly
    if ./build/test/complexity_test; then
        test_status=0
    else
        echo "Build succeeded but test execution failed"
        test_status=1
    fi
else
    # Build failed due to type mismatch errors (this is the bug)
    echo "Build failed due to compilation errors - this is the expected bug state"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
