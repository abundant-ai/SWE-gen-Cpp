#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/re_test.cc" "test/re_test.cc"

# Reconfigure to detect changes
rm -rf build
if ! cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DBENCHMARK_ENABLE_TESTING=ON 2>&1 | tee /tmp/cmake_output.txt; then
    echo "CMake configuration failed" >&2
    test_status=1
else
    # Check if CMake ran the C++ feature checks
    # In HEAD (fixed): Should see "Performing Test HAVE_STD_REGEX" or similar
    # In BASE (buggy): Feature checks are removed from CMakeLists.txt, so no checks run
    if grep -q "Performing Test HAVE_STD_REGEX\|Performing Test HAVE_GNU_POSIX_REGEX\|Performing Test HAVE_POSIX_REGEX" /tmp/cmake_output.txt; then
        echo "C++ feature checks found in CMake output (HEAD/fixed state)" >&2
        has_feature_checks=1
    else
        echo "C++ feature checks NOT found in CMake output (BASE/buggy state)" >&2
        has_feature_checks=0
    fi

    # Build googletest first
    if ! cmake --build build --target googletest 2>&1; then
        echo "Failed to build googletest dependency" >&2
        test_status=1
    # Build re_test
    elif ! cmake --build build --target re_test -j 1 2>&1; then
        echo "Build failed" >&2
        test_status=1
    else
        # Run the re_test to ensure it works
        echo "Running re_test..."
        if ! timeout 30 ./build/test/re_test 2>&1; then
            echo "re_test failed" >&2
            test_status=1
        else
            echo "re_test passed"
            # Success if feature checks were found (HEAD/fixed)
            # Failure if feature checks were not found (BASE/buggy)
            if [ "$has_feature_checks" -eq 1 ]; then
                test_status=0
            else
                test_status=1
            fi
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
