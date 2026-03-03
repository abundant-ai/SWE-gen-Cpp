#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Test that the SIMDJSON_ENABLE_THREADS option exists and is respected
echo "Testing if SIMDJSON_ENABLE_THREADS option exists..."
rm -rf build_test
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_ENABLE_THREADS=OFF -B build_test > cmake_output.txt 2>&1
cmake_status=$?

# Check if the option was actually used (not a warning about unused variable)
if grep -q "Manually-specified variables were not used by the project" cmake_output.txt; then
    echo "ERROR: SIMDJSON_ENABLE_THREADS option does not exist in CMakeLists.txt"
    test_status=1
elif [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    cat cmake_output.txt
    test_status=1
else
    # Verify that the build actually respects the option by checking
    # if Threads::Threads is conditionally linked in src/CMakeLists.txt
    if grep -q "if(SIMDJSON_ENABLE_THREADS)" src/CMakeLists.txt; then
        echo "SUCCESS: Thread linking is conditional on SIMDJSON_ENABLE_THREADS"

        # Build with threads disabled to ensure it works
        echo "Building with threads disabled..."
        cmake --build build_test --target simdjson -j=2 2>&1
        build_status=$?

        if [ $build_status -ne 0 ]; then
            echo "ERROR: Build failed with SIMDJSON_ENABLE_THREADS=OFF"
            test_status=1
        else
            echo "SUCCESS: Build completed with threads disabled"
            test_status=0
        fi
    else
        echo "ERROR: Thread linking is not conditional (if(SIMDJSON_ENABLE_THREADS) not found in src/CMakeLists.txt)"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
