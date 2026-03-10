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

# Rebuild with updated test files (clear build directory to ensure CMake picks up changes)
rm -rf build
mkdir -p build
cd build
cmake .. -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLES=OFF -DSPDLOG_BUILD_BENCH=OFF -DCMAKE_CXX_FLAGS="-DSPDLOG_FMT_PRINTF" 2>&1 || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

make -j2 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run the unit tests (from tests subdirectory where logs directory exists)
cd tests
./catch_tests 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
