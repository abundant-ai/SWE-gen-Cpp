#!/bin/bash

cd /app/src

# Copy the fixed test file to overwrite the buggy version
cp /tests/src/unit-regression.cpp test/src/unit-regression.cpp

# Reconfigure CMake
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=clang-14 -DCMAKE_CXX_COMPILER=clang++-14

# Build the specific test for this PR (one at a time to avoid OOM)
cmake --build . --target test-regression --parallel 1

# Run the specific unit test
ctest -R "test-regression" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
