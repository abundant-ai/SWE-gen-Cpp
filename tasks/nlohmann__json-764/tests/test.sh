#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-class_parser.cpp" "test/src/unit-class_parser.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"

# Rebuild and run the specific tests using CMake
test_status=0

for test_name in test-class_parser test-regression; do
    echo "Building and running $test_name..."
    build_output=$(cmake --build build --target $test_name 2>&1)
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "$build_output"
        echo "Build failed for $test_name with status $build_status"
        test_status=1
        break
    fi

    # Run the test
    test_output=$(./build/test/$test_name 2>&1)
    test_exit=$?
    echo "$test_output"

    if [ $test_exit -ne 0 ] || echo "$test_output" | grep -q "No tests ran"; then
        test_status=1
        break
    fi
done

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
