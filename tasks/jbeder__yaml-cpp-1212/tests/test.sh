#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/cmake"
cp "/tests/cmake/CMakeLists.txt" "test/cmake/CMakeLists.txt"
mkdir -p "test/cmake"
cp "/tests/cmake/main.cpp" "test/cmake/main.cpp"

# Rebuild yaml-cpp with the fix applied (oracle applies fix.patch before running this script)
cmake --build build --config Debug 2>&1
rebuild_status=$?

if [ $rebuild_status -ne 0 ]; then
  echo "Rebuild failed with status $rebuild_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $rebuild_status
fi

# Install yaml-cpp to a prefix so it can be found by the test
CMAKE_INSTALL_PREFIX="/tmp/yaml-cpp-install"
cmake --install build --prefix "${CMAKE_INSTALL_PREFIX}" --config Debug 2>&1
install_status=$?

if [ $install_status -ne 0 ]; then
  echo "Install failed with status $install_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $install_status
fi

# Configure the CMake package test
cmake \
  -S test/cmake \
  -B consumer-build \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_PREFIX_PATH="${CMAKE_INSTALL_PREFIX}" 2>&1
configure_status=$?

if [ $configure_status -ne 0 ]; then
  echo "CMake configuration failed with status $configure_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $configure_status
fi

# Build the CMake package test
cmake --build consumer-build --config Debug 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
