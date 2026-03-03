#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# The fix is about ensuring singleheader tests are excluded from default build
# Test 1: Verify that a normal build does NOT build singleheader test targets
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Build the default target (should NOT include simdjson-singleheader)
    echo "Testing that default build excludes singleheader test targets..."
    cmake --build build 2>&1 | tee build_output.txt
    build_status=$?

    # Check that simdjson-singleheader was NOT built (it should be excluded from default build)
    if grep -q "Building.*simdjson-singleheader" build_output.txt; then
        echo "ERROR: singleheader test target was built in default build (should be excluded)"
        test_status=1
    else
        echo "SUCCESS: singleheader test target correctly excluded from default build"

        # Test 2: Verify that the singleheader test is still available via CTest
        echo "Verifying singleheader test is available via CTest..."
        if ctest --test-dir build -N 2>&1 | grep -q "simdjson-singleheader"; then
            echo "SUCCESS: simdjson-singleheader test is registered with CTest"

            # Test 3: Run the singleheader test explicitly to ensure it works
            echo "Running singleheader test explicitly..."
            ctest --test-dir build -R 'simdjson-singleheader' --output-on-failure
            test_status=$?

            if [ $test_status -eq 0 ]; then
                echo "SUCCESS: singleheader test runs successfully when explicitly invoked"
            else
                echo "ERROR: singleheader test failed when explicitly invoked"
            fi
        else
            echo "ERROR: simdjson-singleheader test not found in CTest"
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
