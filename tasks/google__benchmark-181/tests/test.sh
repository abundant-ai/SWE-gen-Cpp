#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/fixture_test.cc" "test/fixture_test.cc"
mkdir -p "test"
cp "/tests/map_test.cc" "test/map_test.cc"

# Rebuild the specific test targets with updated source files
if ! cmake --build build --target fixture_test -j 1 || ! cmake --build build --target map_test -j 1; then
    echo "Build failed - tests cannot be run" >&2
    test_status=1
else
    # Run only the specific tests for this PR
    cd build
    ctest -R "^(fixture_test|map_test)$" --output-on-failure -V
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
