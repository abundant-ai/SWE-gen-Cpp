#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-msgpack.cpp" "test/src/unit-msgpack.cpp"

# Reconfigure CMake to pick up the updated test files
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON

# Build the specific test
cmake --build . --target test-msgpack

# Run the specific unit test
ctest -R "test-msgpack" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
