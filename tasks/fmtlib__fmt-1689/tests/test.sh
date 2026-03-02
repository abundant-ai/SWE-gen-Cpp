#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/ranges-test.cc" "test/ranges-test.cc"

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
