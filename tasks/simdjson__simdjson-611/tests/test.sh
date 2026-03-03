#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/pointercheck.cpp" "tests/pointercheck.cpp"

# Rebuild project and tests using CMake
echo "Rebuilding project with tests..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Build the pointercheck test target
    echo "Building pointercheck test..."
    cmake --build build --target pointercheck -j=2 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "ERROR: Test build failed"
        test_status=1
    else
        # Run the pointercheck test executable
        echo "Running pointercheck..."
        output=$(./build/tests/pointercheck 2>&1)
        echo "$output"

        # Check if the output contains "Success!" (test passes) or "Failed!" (test fails)
        if echo "$output" | grep -q "Success!"; then
            echo "SUCCESS: pointercheck test passed"
            test_status=0
        else
            echo "ERROR: pointercheck test failed"
            test_status=1
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
