#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-concepts.cpp" "tests/src/unit-concepts.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-deserialization.cpp" "tests/src/unit-deserialization.cpp"

# This PR tests changes to concepts and deserialization
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

# Build and run test-concepts
cmake --build build_test --target test-concepts_cpp11 2>&1 | tee /tmp/build_concepts.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/test-concepts_cpp11 2>&1 | tee /tmp/test_concepts.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-deserialization
cmake --build build_test --target test-deserialization_cpp11 2>&1 | tee /tmp/build_deserialization.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/test-deserialization_cpp11 2>&1 | tee /tmp/test_deserialization.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
