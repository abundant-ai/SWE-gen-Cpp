#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/src"
cp "/tests/src/unit-alt-string.cpp" "test/src/unit-alt-string.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-cbor.cpp" "test/src/unit-cbor.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-class_parser.cpp" "test/src/unit-class_parser.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-comparison.cpp" "test/src/unit-comparison.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-conversions.cpp" "test/src/unit-conversions.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-items.cpp" "test/src/unit-items.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression1.cpp" "test/src/unit-regression1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-ubjson.cpp" "test/src/unit-ubjson.cpp"

# Reconfigure CMake to pick up the updated test files
cmake -S . -B build -DJSON_BuildTests=ON -DJSON_MultipleHeaders=ON \
    -DCMAKE_CXX_FLAGS="-Wconversion -Werror"

# Rebuild the test targets that include the updated test files
# Using cpp11 for all tests to ensure compatibility
cmake --build build --target test-alt-string_cpp11 test-cbor_cpp11 test-class_parser_cpp11 test-comparison_cpp11 test-conversions_cpp11 test-items_cpp11 test-regression1_cpp11 test-regression2_cpp11 test-ubjson_cpp11
build_status=$?

if [ $build_status -ne 0 ]; then
    echo "Build failed"
    test_status=1
else
    # Run the test executables
    test_status=0
    for test_name in alt-string cbor class_parser comparison conversions items regression1 regression2 ubjson; do
        echo "Running test-${test_name}_cpp11..."
        ./build/test/test-${test_name}_cpp11
        status=$?
        if [ $status -ne 0 ]; then
            echo "Test ${test_name} failed"
            test_status=1
            break
        fi
    done
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
