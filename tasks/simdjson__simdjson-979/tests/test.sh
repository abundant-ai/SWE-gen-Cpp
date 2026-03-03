#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Rebuild with the fixed tests/CMakeLists.txt
# The fix adds proper conditional checks in tools/CMakeLists.txt for cxxopts dependency
rm -rf build
cmake_output=$(cmake -DCMAKE_BUILD_TYPE=Debug -B build 2>&1)
cmake_status=$?
echo "$cmake_output"

# The fix should produce a message about cxxopts in tools/CMakeLists.txt
# Either "We have cxxopts..." or "We are missing cxxopts..."
# The buggy version doesn't have this conditional check, so it won't print either message
if echo "$cmake_output" | grep -q "cxxopts as a dependency"; then
    echo "SUCCESS: tools/CMakeLists.txt has proper cxxopts dependency check"

    if [ $cmake_status -ne 0 ]; then
        echo "ERROR: CMake configuration failed"
        test_status=1
    else
        # Build tests to verify everything works
        cmake --build build --target basictests
        build_status=$?

        if [ $build_status -ne 0 ]; then
            echo "ERROR: Build failed"
            test_status=1
        else
            ctest --test-dir build -R 'basictests' --output-on-failure
            test_status=$?
        fi
    fi
else
    echo "ERROR: Expected CMake message about cxxopts dependency check not found"
    echo "This indicates tools/CMakeLists.txt fix is not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
