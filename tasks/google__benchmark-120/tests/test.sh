#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/fixture_test.cc" "test/fixture_test.cc"

# Reconfigure CMake with the updated test files
# This verifies that the changes to test/CMakeLists.txt and test/fixture_test.cc work correctly
if ! rm -rf build || ! cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_ENABLE_TESTING=ON; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Build the fixture_test specifically to verify the changes
    if ! cmake --build build --target fixture_test -j 1; then
        echo "Build failed - test file changes broke the build" >&2
        test_status=1
    else
        # Run the fixture_test to verify it works correctly
        cd build
        if ! ctest --output-on-failure -V -R fixture_test; then
            echo "fixture_test failed" >&2
            test_status=1
        else
            test_status=0
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
