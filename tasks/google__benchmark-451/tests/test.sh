#!/bin/bash

cd /app/src

test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/cxx03_test.cc" "test/cxx03_test.cc"
mkdir -p "test"
cp "/tests/templated_fixture_test.cc" "test/templated_fixture_test.cc"

# Rebuild the specific tests affected by the changes
if ! cmake --build build --config Debug -j 1; then
    echo "Build failed after applying HEAD test files" >&2
    test_status=1
else
    # Run the specific test binaries for cxx03_test and templated_fixture_test
    ./build/test/cxx03_test
    if [ $? -ne 0 ]; then
        test_status=1
    fi

    ./build/test/templated_fixture_test
    if [ $? -ne 0 ]; then
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
