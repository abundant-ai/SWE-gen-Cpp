#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/test.cpp" "test/test.cpp"
mkdir -p "test"
cp "/tests/test_wchar_t.cpp" "test/test_wchar_t.cpp"

# Rebuild the test with the updated source (test files were copied above)
cd /app/src
rm -rf build
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --target test-cpp17 test_wchar_t-cpp17 -- -j2

# Run the specific tests for test.cpp and test_wchar_t.cpp
ctest --output-on-failure -R "test-cpp17|test_wchar_t-cpp17"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
