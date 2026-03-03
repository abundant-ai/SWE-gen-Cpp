#!/bin/bash

cd /app/src

# Copy HEAD files from /tests (overwrites BASE state with fixed versions)
# These files restore the regex wrapper functionality that was removed by bug.patch
mkdir -p "src"
cp "/tests/re.cc" "src/re.cc"
cp "/tests/re.h" "src/re.h"
cp "/tests/src_CMakeLists.txt" "src/CMakeLists.txt"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
cp "/tests/re_test.cc" "test/re_test.cc"

# Reconfigure to detect changes
rm -rf build
if ! cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_ENABLE_TESTING=ON 2>&1; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Try to build re_test
    # In BASE (buggy): Will fail because regex wrapper files don't exist
    # In HEAD (fixed): Will succeed because we copied the regex wrapper files
    if ! cmake --build build --target re_test -j 1 2>&1; then
        echo "Build failed (expected in BASE/buggy state)" >&2
        test_status=1
    else
        # Run the re_test to ensure it works
        echo "Running re_test..."
        if ! timeout 30 ./build/test/re_test 2>&1; then
            echo "re_test execution failed" >&2
            test_status=1
        else
            echo "re_test passed (HEAD/fixed state)"
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
