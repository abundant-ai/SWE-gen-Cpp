#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/core-test.cc" "test/core-test.cc"
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/ostream-test.cc" "test/ostream-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

test_status=0

# Reconfigure CMake to rebuild the tests
# Add -Werror=non-virtual-dtor to catch the bug
echo "Reconfiguring CMake..."
cd build
if ! cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_CXX_FLAGS="-Werror=non-virtual-dtor" 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    test_status=1
fi

# Build and run core-test
if [ $test_status -eq 0 ]; then
    echo "Building core-test..."
    if ! cmake --build . --target core-test 2>&1; then
        echo "FAIL: core-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running core-test..."
    if ! ./bin/core-test 2>&1; then
        echo "FAIL: core-test execution failed"
        test_status=1
    else
        echo "PASS: core-test passed"
    fi
fi

# Build and run format-test
if [ $test_status -eq 0 ]; then
    echo "Building format-test..."
    if ! cmake --build . --target format-test 2>&1; then
        echo "FAIL: format-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running format-test..."
    if ! ./bin/format-test 2>&1; then
        echo "FAIL: format-test execution failed"
        test_status=1
    else
        echo "PASS: format-test passed"
    fi
fi

# Build and run ostream-test
if [ $test_status -eq 0 ]; then
    echo "Building ostream-test..."
    if ! cmake --build . --target ostream-test 2>&1; then
        echo "FAIL: ostream-test build failed"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "Running ostream-test..."
    if ! ./bin/ostream-test 2>&1; then
        echo "FAIL: ostream-test execution failed"
        test_status=1
    else
        echo "PASS: ostream-test passed"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
