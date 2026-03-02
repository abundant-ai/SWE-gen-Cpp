#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/enforce-compile-string-test.cc" "test/enforce-compile-string-test.cc"
mkdir -p "test"
cp "/tests/ranges-test.cc" "test/ranges-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

test_status=0

# Reconfigure CMake after copying new test files
echo "Reconfiguring CMake..."
cd build
if ! cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    test_status=1
fi

# Build and run enforce-compile-string-test
if [ $test_status -eq 0 ]; then
    echo "Building enforce-compile-string-test..."
    if ! cmake --build . --target enforce-compile-string-test 2>&1; then
        echo "FAIL: enforce-compile-string-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running enforce-compile-string-test..."
    if ! ./bin/enforce-compile-string-test 2>&1; then
        echo "FAIL: enforce-compile-string-test execution failed"
        test_status=1
    else
        echo "PASS: enforce-compile-string-test passed"
    fi
fi

# Build and run ranges-test
if [ $test_status -eq 0 ]; then
    echo "Building ranges-test..."
    if ! cmake --build . --target ranges-test 2>&1; then
        echo "FAIL: ranges-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running ranges-test..."
    if ! ./bin/ranges-test 2>&1; then
        echo "FAIL: ranges-test execution failed"
        test_status=1
    else
        echo "PASS: ranges-test passed"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
