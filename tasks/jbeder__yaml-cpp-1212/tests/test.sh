#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/cmake"
cp "/tests/cmake/CMakeLists.txt" "test/cmake/CMakeLists.txt"
cp "/tests/cmake/main.cpp" "test/cmake/main.cpp"

# Install yaml-cpp to a test prefix so CMake can find it
cd build
echo "=== Installing yaml-cpp to test prefix ==="
cmake .. -DCMAKE_INSTALL_PREFIX=/tmp/yaml-cpp-install
if ! make install 2>&1; then
    echo "FAIL: Install failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Build the CMake consumer test to verify package config exports correct variables
cd /app/src/test/cmake
mkdir -p build
cd build
echo "=== Building CMake consumer test ==="
if ! cmake .. -DCMAKE_PREFIX_PATH=/tmp/yaml-cpp-install 2>&1; then
    echo "FAIL: CMake configuration failed - likely missing YAML_CPP_SHARED_LIBS_BUILT variable"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! make 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
