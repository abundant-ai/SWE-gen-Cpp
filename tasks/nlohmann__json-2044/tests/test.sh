#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-cbor.cpp" "test/src/unit-cbor.cpp"

# Reconfigure CMake to pick up the updated test files
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=clang-14 -DCMAKE_CXX_COMPILER=clang++-14 \
    -DCMAKE_CXX_FLAGS="-Wsign-conversion -Wshorten-64-to-32 -Werror"

# Build the specific test for this PR (one at a time to avoid OOM)
cmake --build . --target test-cbor --parallel 1

# Run the specific unit test
ctest -R "test-cbor" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
