#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"

# Rebuild the specific test binary with AddressSanitizer to detect memory leaks
# Use GCC-compatible ASAN flags instead of the Clang-specific JSON_Sanitizer option
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON \
    -DCMAKE_CXX_FLAGS="-g -O0 -fsanitize=address -fsanitize=leak -fno-omit-frame-pointer"
ninja test-regression2

# Run the test binary which contains the test for issue #2865 (memory leak)
# The test will fail in BASE state (with memory leak) and pass in HEAD state (leak fixed)
ASAN_OPTIONS=halt_on_error=1:detect_leaks=1 ./test/test-regression2
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
