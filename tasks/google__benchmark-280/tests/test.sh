#!/bin/bash

cd /app/src

test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"

# This PR adds the BENCHMARK_USE_LIBCXX CMake option.
# Test: Try to configure with -DBENCHMARK_USE_LIBCXX=OFF and check if the option is recognized

# Reconfigure with BENCHMARK_USE_LIBCXX option
rm -rf build
cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_USE_LIBCXX=OFF 2>&1 | tee /tmp/cmake_output.txt

cmake_status=${PIPESTATUS[0]}

if [ $cmake_status -ne 0 ]; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Check if CMake warned that the variable was not used
    # In BASE state (without fix), CMake will warn "Manually-specified variables were not used"
    # In HEAD state (with fix), the option will be properly used and no warning
    if grep -q "Manually-specified variables were not used" /tmp/cmake_output.txt && \
       grep -q "BENCHMARK_USE_LIBCXX" /tmp/cmake_output.txt; then
        echo "BENCHMARK_USE_LIBCXX option is NOT recognized by the project (FAIL)" >&2
        test_status=1
    else
        echo "BENCHMARK_USE_LIBCXX option is available and recognized (PASS)"
        # Build to make sure everything works
        if cmake --build build --config Debug -j 1; then
            test_status=0
        else
            echo "Build failed after configuration" >&2
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
