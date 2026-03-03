#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
cp "/tests/re_test.cc" "test/re_test.cc"

# The buggy state has googletest ExternalProject in main CMakeLists.txt
# The HEAD state moves it to test/CMakeLists.txt
# To avoid "target already exists" error, remove googletest from main CMakeLists.txt
sed -i '/^# Import and build Google Test/,/^link_directories(${binary_dir})$/d' CMakeLists.txt

# Fix googletest URL in test/CMakeLists.txt (googlecode.com is dead)
GTEST_MD5=$(md5sum /app/gtest-1.7.0.zip | cut -d' ' -f1)
sed -i "s|https://googletest.googlecode.com/files/gtest-1.7.0.zip|file:///app/gtest-1.7.0.zip|g" test/CMakeLists.txt
sed -i "s|2d6ec8ccdf5c46b05ba54a9fd1d130d7|${GTEST_MD5}|g" test/CMakeLists.txt

# Reconfigure and rebuild with the updated test files
if ! rm -rf build || ! cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_ENABLE_TESTING=ON; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Build googletest first (it's an external project dependency)
    if ! cmake --build build --target googletest; then
        echo "Failed to build googletest dependency" >&2
        test_status=1
    # Build the specific tests to verify the changes
    elif ! cmake --build build --target benchmark_test -j 1 || ! cmake --build build --target re_test -j 1; then
        echo "Build failed - test file changes broke the build" >&2
        test_status=1
    else
        # Run benchmark_test executable - just verify it runs and builds correctly
        # Don't check exact count to avoid benchmark timing issues
        if ! timeout 60 ./build/test/benchmark_test --benchmark_min_time=0.01 51; then
            echo "benchmark_test execution failed" >&2
            test_status=1
        # Run re_test executable
        elif ! ./build/test/re_test; then
            echo "re_test execution failed" >&2
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
