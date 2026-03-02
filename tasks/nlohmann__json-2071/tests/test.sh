#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-constructor1.cpp" "test/src/unit-constructor1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"

# Reconfigure CMake to pick up the updated test files
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON

# Build the specific tests for this PR (one at a time to avoid OOM)
cmake --build . --target test-constructor1 --parallel 1
cmake --build . --target test-regression --parallel 1

# Run the specific unit tests
ctest -R "test-(constructor1|regression)" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
