#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"
mkdir -p "test/src"
cp "/tests/src/unit-merge_patch.cpp" "test/src/unit-merge_patch.cpp"

# Rebuild and run the specific test using CMake
build_output=$(cmake --build build --target test-merge_patch 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run test-merge_patch
    test_output=$(./build/test/test-merge_patch 2>&1)
    test_exit=$?
    echo "$test_output"

    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
    else
        test_status=0
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
