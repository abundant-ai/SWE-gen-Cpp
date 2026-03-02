#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/benchmarks/src"
cp "/tests/benchmarks/src/benchmarks.cpp" "tests/benchmarks/src/benchmarks.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-msgpack.cpp" "tests/src/unit-msgpack.cpp"

# This PR tests changes to benchmarks and msgpack
# Re-configure and build with the updated test files
cmake -S . -B build_test -DJSON_BuildTests=ON > /tmp/cmake_output.txt 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    cat /tmp/cmake_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Download test data for the new build directory
cmake --build build_test --target download_test_data > /tmp/download_test_data.txt 2>&1

# Build and run each test executable that corresponds to the modified test files
test_status=0

# Build and run test-msgpack
cmake --build build_test --target test-msgpack_cpp11 2>&1 | tee /tmp/build_msgpack.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/test-msgpack_cpp11 2>&1 | tee /tmp/test_msgpack.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build benchmarks (just ensure it compiles, don't run as it's not a test)
# Note: Benchmarks need to be built in their own directory
cd tests/benchmarks
cmake -S . -B build_bench 2>&1 | tee /tmp/cmake_benchmarks.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    cmake --build build_bench --target json_benchmarks 2>&1 | tee /tmp/build_benchmarks.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi
cd /app/src

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
