#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp" || true

# This PR fixes weak-vtables warnings when compiling with Clang -Wweak-vtables -Werror
# The BASE state (bug applied) will fail to compile with these flags because:
# 1. bug.patch removes -Wno-weak-vtables from cmake/ci.cmake
# 2. bug.patch removes the out-of-line destructor implementations from test file
# 3. bug.patch removes pragma suppression from headers
# The test builds with Clang CI configuration which uses -Werror -Weverything (including -Wweak-vtables)

# Configure with CI settings - this will use strict clang flags including -Wweak-vtables
export CXX=clang++-18
export CXXFLAGS="-Werror -Weverything -Wno-c++98-compat -Wno-c++98-compat-pedantic -Wno-deprecated-declarations -Wno-extra-semi-stmt -Wno-padded -Wno-covered-switch-default -Wno-unsafe-buffer-usage -Wno-reserved-identifier"

# Re-configure and build with the test file
cmake -S . -B build_test -DJSON_BuildTests=ON -DCMAKE_BUILD_TYPE=Debug > /tmp/cmake_output.txt 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    cat /tmp/cmake_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Build the specific test executable - this will fail in BASE state due to weak-vtables warning
cmake --build build_test --target test-regression2_cpp11 2>&1 | tee /tmp/build_output.txt
build_status=${PIPESTATUS[0]}

if [ $build_status -ne 0 ]; then
    # Build failed - check if it's due to weak-vtables warning
    if grep -q "weak-vtables" /tmp/build_output.txt; then
        echo "Build failed due to weak-vtables warning (expected in BASE state)" >&2
    fi
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# If build succeeded, run the test
build_test/tests/test-regression2_cpp11 2>&1 | tee /tmp/test_output.txt
test_status=${PIPESTATUS[0]}

# Check if tests actually ran (not just an empty test file)
if grep -q "test cases: 0" /tmp/test_output.txt; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
