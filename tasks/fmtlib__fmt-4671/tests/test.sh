#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test_c.c" "test/test_c.c"

# Reconfigure and rebuild to pick up any CMakeLists.txt changes and new test file
# This ensures the test-c-api target is built if CMakeLists.txt includes it
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_TEST=ON
cmake --build build --parallel $(nproc)

# Run the specific C API test (located in build/bin/)
# This will fail if test-c-api doesn't exist (buggy state without C API in CMakeLists.txt)
./build/bin/test-c-api
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
