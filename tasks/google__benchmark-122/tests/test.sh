#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"

# Reconfigure CMake with the updated test/CMakeLists.txt
# This verifies that the changes to test/CMakeLists.txt work correctly
if ! rm -rf build || ! cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_ENABLE_TESTING=ON; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Build all test targets to verify the CMakeLists.txt changes work
    if ! cmake --build build -j 1; then
        echo "Build failed - CMakeLists.txt changes broke the build" >&2
        test_status=1
    else
        # Run the test suite to verify everything still works
        cd build
        ctest --output-on-failure -V
        test_status=$?
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
