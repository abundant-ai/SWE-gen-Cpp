#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"

# Build basictests using Make
echo "Building basictests with Make..."
make basictests > /dev/null 2>&1
build_status=$?

if [ $build_status -ne 0 ]; then
    echo "ERROR: Build failed"
    test_status=1
else
    echo "Running basictests..."
    ./basictests
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
