#!/bin/bash

cd /app/src

# Do NOT copy test files - the fix.patch should include test file changes
# This way NOP keeps BASE (buggy) test files, Oracle gets HEAD (fixed) test files

# Reconfigure and rebuild
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
    if ! cmake --build build --target googletest 2>&1; then
        echo "Failed to build googletest dependency" >&2
        test_status=1
    # Build the specific test to verify the changes
    elif ! cmake --build build --target benchmark_test -j 1 2>&1; then
        echo "Build failed" >&2
        test_status=1
    else
        # Run benchmark_test with deliberate wrong expected count to test validation
        # - BASE (buggy): No TestReporter, ignores count argument, exits 0 even with wrong count
        # - HEAD (fixed): Has TestReporter, detects count mismatch, exits non-zero
        # Use Factorial filter (should run 1 test) but claim we expect 999
        echo "Running benchmark_test with wrong expected count (999)..."
        if timeout 30 ./build/test/benchmark_test --benchmark_filter=Factorial 999 2>&1; then
            # Test succeeded despite wrong count - this is BASE (buggy, no validation)
            echo "Test succeeded with wrong count - no validation detected (BASE/buggy)" >&2
            test_status=1
        else
            # Test failed due to count mismatch - this is HEAD (fixed, validation working)
            echo "Test failed with wrong count - validation detected (HEAD/fixed)"
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
