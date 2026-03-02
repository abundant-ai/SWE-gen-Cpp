#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/header_dependencies"
cp "/tests/header_dependencies/CMakeLists.txt" "tests/header_dependencies/CMakeLists.txt"
mkdir -p "tests/header_dependencies"
cp "/tests/header_dependencies/main.c" "tests/header_dependencies/main.c"
mkdir -p "tests/header_dependencies"
cp "/tests/header_dependencies/main.cpp" "tests/header_dependencies/main.cpp"

# Build and run header dependency tests using CMake
mkdir -p build
cd build
cmake -DSPDLOG_BUILD_TESTS=ON .. 2>&1 || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Build only the header_dependencies target
cmake --build . --target header_dependencies 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
