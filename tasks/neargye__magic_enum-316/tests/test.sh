#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test_containers.cpp" "test/test_containers.cpp"

# Rebuild the test with the updated source (test file was copied above)
cd /app/src
rm -rf build
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j 4

# Run the specific test for test_containers.cpp
ctest --output-on-failure -R test_containers-cpp17
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
