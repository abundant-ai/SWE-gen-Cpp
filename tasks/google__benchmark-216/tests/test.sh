#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/diagnostics_test.cc" "test/diagnostics_test.cc"

# Rebuild the specific test target with updated source file
if ! cmake --build build --target diagnostics_test -j 1; then
    echo "Build failed - tests cannot be run" >&2
    test_status=1
else
    # Run only the specific test for this PR
    cd build
    ctest -R "^diagnostics_test$" --output-on-failure -V
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
