#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
cp "/tests/src/unit-udt_macro.cpp" "test/src/unit-udt_macro.cpp"

# Reconfigure CMake to pick up the updated CMakeLists.txt that includes unit-udt_macro
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON

# Build the test
cmake --build . --target test-udt_macro

# Run the specific unit tests
ctest -R "test-udt_macro" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
