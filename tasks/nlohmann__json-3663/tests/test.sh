#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/src"
cp "/tests/src/unit-element_access2.cpp" "tests/src/unit-element_access2.cpp"
cp "/tests/src/unit-type_traits.cpp" "tests/src/unit-type_traits.cpp"

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

# Build and run the test executables that correspond to the modified test files
test_status=0

# Build and run test-element_access2_cpp11
target="test-element_access2_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-type_traits_cpp11
target="test-type_traits_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
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
