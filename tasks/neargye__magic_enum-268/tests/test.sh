#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/test_containers.cpp" "test/test_containers.cpp"

# Rebuild tests with updated test files
cd build
cmake --build .
build_status=$?

# If build fails, the test fails
if [ $build_status -ne 0 ]; then
  test_status=1
else
  # Run the specific test executable for test_containers.cpp
  # The test is built for multiple C++ standards, we'll run the C++17 version
  cd test
  ./test_containers-cpp17
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
