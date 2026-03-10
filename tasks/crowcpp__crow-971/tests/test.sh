#!/bin/bash
set -eo pipefail

cd /app/src

# Set sanitizer options for tests
export ASAN_OPTIONS="strict_string_checks=1:detect_stack_use_after_return=1:check_initialization_order=1:strict_init_order=1:detect_leaks=0"
export UBSAN_OPTIONS="print_stacktrace=1"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Reconfigure CMake WITHOUT sanitizers to reduce memory usage during rebuild
# Add ASIO_NO_DEPRECATED to test that deprecated APIs are not used
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_ENABLE_SSL=ON \
    -DCROW_ENABLE_COMPRESSION=ON \
    -DCROW_ENABLE_SANITIZERS=OFF \
    -DCMAKE_CXX_FLAGS="-DASIO_NO_DEPRECATED" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to include the updated test files
if ! cmake --build build --target unittest 2>&1; then
    echo "FAIL: Build with updated test files failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run tests - validates the code compiles with ASIO_NO_DEPRECATED and runs correctly
if ! ./build/tests/unittest 2>&1; then
    echo "FAIL: Tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: All tests passed"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
