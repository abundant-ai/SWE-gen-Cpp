#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-element_access1.cpp" "test/src/unit-element_access1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-element_access2.cpp" "test/src/unit-element_access2.cpp"

# Rebuild and run the specific tests using CMake
build_output=$(cmake --build build --target test-element_access1 test-element_access2 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run test-element_access1
    test_output1=$(./build/test/test-element_access1 2>&1)
    test_exit1=$?
    echo "$test_output1"

    # Run test-element_access2
    test_output2=$(./build/test/test-element_access2 2>&1)
    test_exit2=$?
    echo "$test_output2"

    if [ $test_exit1 -ne 0 ] || echo "$test_output1" | grep -q "No tests ran" || \
       [ $test_exit2 -ne 0 ] || echo "$test_output2" | grep -q "No tests ran"; then
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
