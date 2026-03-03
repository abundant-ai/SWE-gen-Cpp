#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"

# Reconfigure and rebuild with the updated test files
# Enable Clang with -Wshorten-64-to-32 -Werror to catch narrowing warnings (the bug)
# Add -Wno-error=implicit-const-int-float-conversion to work around walltime.cc issue
if ! rm -rf build || ! cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DCMAKE_CXX_FLAGS="-Wshorten-64-to-32 -Werror -Wno-error=implicit-const-int-float-conversion" \
    -DBENCHMARK_ENABLE_TESTING=ON; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Build googletest first (it's an external project dependency)
    if ! cmake --build build --target googletest 2>&1; then
        echo "Failed to build googletest dependency" >&2
        test_status=1
    # Build the specific test to verify the changes
    # This will fail in buggy state due to narrowing warnings with -Wshorten-64-to-32 -Werror
    elif ! cmake --build build --target benchmark_test -j 1 2>&1; then
        echo "Build failed - likely due to type narrowing warnings (expected in buggy state)" >&2
        test_status=1
    else
        # Run benchmark_test executable - just verify it runs and builds correctly
        # Don't pass expected count - let it auto-detect to avoid count mismatches
        if ! timeout 180 ./build/test/benchmark_test --benchmark_min_time=0.01; then
            echo "benchmark_test execution failed" >&2
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
