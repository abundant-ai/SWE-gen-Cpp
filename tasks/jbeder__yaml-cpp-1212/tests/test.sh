#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/cmake"
cp "/tests/cmake/CMakeLists.txt" "test/cmake/CMakeLists.txt"
cp "/tests/cmake/main.cpp" "test/cmake/main.cpp"

# Rebuild yaml-cpp (oracle applies fix.patch before running this script,
# so we need to rebuild to get the fixed version)
cmake --build build --config Debug --parallel 2>&1
rebuild_status=$?

if [ $rebuild_status -ne 0 ]; then
  echo "Rebuild failed with status $rebuild_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $rebuild_status
fi

# Install yaml-cpp so the CMake consumer test can find it
cmake --install build --prefix /usr/local 2>&1
install_status=$?

if [ $install_status -ne 0 ]; then
  echo "Install failed with status $install_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $install_status
fi

# Build the CMake consumer test
cd test/cmake
cmake -B build -DCMAKE_PREFIX_PATH=/usr/local 2>&1
config_status=$?

if [ $config_status -ne 0 ]; then
  echo "CMake configuration failed with status $config_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $config_status
fi

cmake --build build 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
