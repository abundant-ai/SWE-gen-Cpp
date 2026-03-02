#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/module_cpp20"
cp "/tests/module_cpp20/CMakeLists.txt" "tests/module_cpp20/CMakeLists.txt"
cp "/tests/module_cpp20/main.cpp" "tests/module_cpp20/main.cpp"

# Rebuild the test with the updated code (from /tests)
# C++20 modules require Ninja generator
if ! cmake -G Ninja -S tests/module_cpp20 -B tests/module_cpp20/build; then
    echo "CMake configuration failed for module_cpp20"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! cmake --build tests/module_cpp20/build; then
    echo "Build failed for module_cpp20"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable
cd tests/module_cpp20/build
./json_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
